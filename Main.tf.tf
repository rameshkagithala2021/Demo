provider "aws" {
   profile    = "default"
   region     = "us-west-2"
 }
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2022-03-13",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "aws_eks" {
  name     = "eks_cluster_tuto"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = ["subnet-4d0d3324", "subnet-b3a8f9c8"]
  }

  tags = {
    Name = "EKS_demo"
  }
}

resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group-demo"

  assume_role_policy = <<POLICY
{
  "Version": "2022-03-13",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "node_tuto"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = ["<subnet-1>", "<subnet-2>"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
resource "aws_security_group" "zookeeper" {  
  name        = "zookeeper-security-group"  
  description = "Allow Zookeeper traffic"  
  vpc_id      = "${data.aws_vpc.vpc.id}"
  ingress {
    from_port       = 2181
    to_port         = 2181
    protocol        = "tcp"
    security_groups = ${data.aws_security_group.kafka.id}
  }
  ingress {
    from_port   = 2888
    to_port     = 2888
    protocol    = "tcp"
    self        = true
  }
  ingress {
    from_port   = 3888
    to_port     = 3888
    protocol    = "tcp"
    self        = true
  }
}
resource "aws_security_group" "zookeeper" {
  name        = "zookeeper-security-group"
  description = "Allow Zookeeper traffic"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}
resource "aws_security_group_rule" "allow_zookeeper_quorum" {
  type                     = "ingress"
  from_port                = "2181"
  to_port                  = "2181"
  protocol                 = "tcp"
  source_security_group_id = "${data.aws_security_group.kafka.id}"
  
  security_group_id = "${aws_security_group.zookeeper.id}"
}
resource "aws_instance" "zookeeper" {
  ami           = "${data.aws_ami.image_latest.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id =   
            "${tolist(data.aws_subnet_ids.public_subnets.ids)[2]}"
  availability_zone           = "${var.availability_zone}"
  associate_public_ip_address = true
  
  vpc_security_group_ids = 
                  ["${data.aws_security_group.kafka_cluster.id}",
                   "${aws_security_group.zookeeper.id}"]
  depends_on = ["aws_security_group.zookeeper"]
  count      = "${var.instance_count}"
}
root_block_device {
    volume_size = "${var.volume_size}"
  }