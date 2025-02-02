resource "aws_instance" "citus_coordinator" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = data.aws_subnet.az1.id
  iam_instance_profile = data.aws_iam_instance_profile.iam_profile.name
  security_groups      = [data.aws_security_group.sg.id]

  key_name = var.keypair

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
    encrypted   = true
    kms_key_id  = data.aws_kms_key.kms_key.key_id
    tags        = {}
  }
  lifecycle {
    ignore_changes = [security_groups, capacity_reservation_specification, cpu_options, enclave_options, maintenance_options, metadata_options, private_dns_name_options]
  }

  tags = {
    Name = "Coordinator"
  }
}

resource "aws_instance" "citus_worker_1" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = data.aws_subnet.az2.id
  iam_instance_profile = data.aws_iam_instance_profile.iam_profile.name
  security_groups      = [data.aws_security_group.sg.id]

  key_name = var.keypair

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
    encrypted   = true
    kms_key_id  = data.aws_kms_key.kms_key.key_id
    tags        = {}
  }
  lifecycle {
    ignore_changes = [security_groups, capacity_reservation_specification, cpu_options, enclave_options, maintenance_options, metadata_options, private_dns_name_options]
  }

  tags = {
    Name = "Citus Worker 1"
  }
}

resource "aws_instance" "citus_worker_2" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = data.aws_subnet.az3.id
  iam_instance_profile = data.aws_iam_instance_profile.iam_profile.name
  security_groups      = [data.aws_security_group.sg.id]

  key_name = var.keypair

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
    encrypted   = true
    kms_key_id  = data.aws_kms_key.kms_key.key_id
    tags        = {}
  }
  lifecycle {
    ignore_changes = [security_groups, capacity_reservation_specification, cpu_options, enclave_options, maintenance_options, metadata_options, private_dns_name_options]
  }

  tags = {
    Name = "Citus Worker 2"
  }
}

locals {
  instance_ips = [aws_instance.citus_coordinator.private_ip, aws_instance.citus_worker_1.private_ip, aws_instance.citus_worker_2.private_ip]
}


resource "null_resource" "install_postgres" {
  count = length(local.instance_ips)
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt install postgresql postgresql-client -y",
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql"
    ]
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file("~/.ssh/${var.keypair}")
    host        = local.instance_ips[count.index]
  }
  depends_on = [aws_instance.citus_coordinator, aws_instance.citus_worker_1, aws_instance.citus_worker_2]
}

resource "null_resource" "install_citus" {
  count = length(local.instance_ips)
  provisioner "remote-exec" {
    inline = [
      "curl https://install.citusdata.com/community/deb.sh | sudo bash",
      "sudo apt-get -y install postgresql-14-citus-12.1",
      "sudo pg_conftool 14 main set shared_preload_libraries citus",
      "sudo pg_conftool 14 main set listen_addresses '*'",
      "echo 'host    all             all             10.0.0.0/8              trust' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf",
      "echo 'host    all             all             127.0.0.1/32            trust' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf",
      "echo 'host    all             all             ::1/128                 trust' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf",
      "sudo service postgresql restart",
      "sudo -i -u postgres psql -c 'CREATE EXTENSION citus;'"
    ]

  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file("~/.ssh/${var.keypair}")
    host        = local.instance_ips[count.index]
  }
  depends_on = [aws_instance.citus_coordinator, aws_instance.citus_worker_1, aws_instance.citus_worker_2, null_resource.install_postgres]
}

resource "null_resource" "citus_coordinator_exec" {
  provisioner "remote-exec" {
    inline = [
      "sudo -i -u postgres psql -c \"SELECT citus_set_coordinator_host('${aws_instance.citus_coordinator.private_ip}', 5432);\"",
      "sudo -i -u postgres psql -c \"SELECT * from citus_add_node('${aws_instance.citus_worker_1.private_ip}', 5432);\"",
      "sudo -i -u postgres psql -c \"SELECT * from citus_add_node('${aws_instance.citus_worker_2.private_ip}', 5432);\"",
      "sudo -i -u postgres psql -c \"SELECT * FROM citus_get_active_worker_nodes();\""

    ]
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file("~/.ssh/${var.keypair}")
    host        = aws_instance.citus_coordinator.private_ip
  }
  depends_on = [aws_instance.citus_coordinator, null_resource.install_citus]
}
