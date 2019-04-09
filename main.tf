variable "region1_cluster_name" {
  default = "tf-region1"
}

variable "region2_cluster_name" {
  default = "tf-region2"
}

variable "region3_cluster_name" {
  default = "tf-region3"
}

variable "project_id" {
  default = ""
}

variable "region1" {
  default = "us-central1"
}

variable "region2" {
  default = "europe-west1"
}

variable "region3" {
  default = "asia-south1"
}


variable "network_name" {
  default = "tf-gke-multi-region"
}

provider "google" {
  region = "${var.region1}"
}

data "google_client_config" "current" {}

resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "region1" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.126.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region1}"
}

resource "google_compute_subnetwork" "region2" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.127.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region2}"
}

resource "google_compute_subnetwork" "region3" {
  name          = "${var.network_name}"
  ip_cidr_range = "10.128.0.0/20"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region3}"
}

module "cluster1" {
  source       = "./source"
  region       = "${var.region1}"
  cluster_name = "${var.region1_cluster_name}"
  tags         = ["tf-gke-region1"]
  network      = "${google_compute_subnetwork.region1.network}"
  subnetwork   = "${google_compute_subnetwork.region1.name}"
}

module "cluster2" {
  source       = "./source"
  region       = "${var.region2}"
  cluster_name = "${var.region2_cluster_name}"
  tags         = ["tf-gke-region2"]
  network      = "${google_compute_subnetwork.region2.network}"
  subnetwork   = "${google_compute_subnetwork.region2.name}"
}
  
  module "cluster3" {
  source       = "./source"
  region       = "${var.region3}"
  cluster_name = "${var.region3_cluster_name}"
  tags         = ["tf-gke-region3"]
  network      = "${google_compute_subnetwork.region3.network}"
  subnetwork   = "${google_compute_subnetwork.region3.name}"
}

provider "kubernetes" {
  alias                  = "cluster1"
  host                   = "${module.cluster1.endpoint}"
  token                  = "${data.google_client_config.current.access_token}"
  client_certificate     = "${base64decode(module.cluster1.client_certificate)}"
  client_key             = "${base64decode(module.cluster1.client_key)}"
  cluster_ca_certificate = "${base64decode(module.cluster1.cluster_ca_certificate)}"
}

provider "kubernetes" {
  alias                  = "cluster2"
  host                   = "${module.cluster2.endpoint}"
  token                  = "${data.google_client_config.current.access_token}"
  client_certificate     = "${base64decode(module.cluster2.client_certificate)}"
  client_key             = "${base64decode(module.cluster2.client_key)}"
  cluster_ca_certificate = "${base64decode(module.cluster2.cluster_ca_certificate)}"
}
    
provider "kubernetes" {
  alias                  = "cluster3"
  host                   = "${module.cluster3.endpoint}"
  token                  = "${data.google_client_config.current.access_token}"
  client_certificate     = "${base64decode(module.cluster3.client_certificate)}"
  client_key             = "${base64decode(module.cluster3.client_key)}"
  cluster_ca_certificate = "${base64decode(module.cluster3.cluster_ca_certificate)}"
}

module "cluster1_app" {
  source      = "./k8s-app"
  #external_ip = "${module.glb.external_ip}"
  node_port   = 30000
  project_id = "${var.project_id}"

  providers = {
    kubernetes = "kubernetes.cluster1"
  }
}

module "cluster2_app" {
  source      = "./k8s-app"
  #external_ip = "${module.glb.external_ip}"
  node_port   = 30000
  project_id = "${var.project_id}"

  providers = {
    kubernetes = "kubernetes.cluster2"
  }
}

module "cluster3_app" {
  source      = "./k8s-app"
  #external_ip = "${module.glb.external_ip}"
  node_port   = 30000
  project_id = "${var.project_id}"

  providers = {
    kubernetes = "kubernetes.cluster3"
  }
}  
  
#module "glb" {
#  source            = "GoogleCloudPlatform/lb-http/google"
#  version           = "1.0.10"
#  name              = "gke-multi-regional"
#  target_tags       = ["tf-gke-region1", "tf-gke-region2", "tf-gke-region3"]
#  firewall_networks = ["${google_compute_network.default.name}"]
#
#  backends = {
#    "0" = [
#      {
#        group = "${element(module.cluster1.instance_groups, 0)}"
#      },
#      {
#        group = "${element(module.cluster1.instance_groups, 1)}"
#      },
#      {
#        group = "${element(module.cluster1.instance_groups, 2)}"
#      },
#      {
#        group = "${element(module.cluster2.instance_groups, 0)}"
#      },
#      {
#        group = "${element(module.cluster2.instance_groups, 1)}"
#      },
#      {
#        group = "${element(module.cluster2.instance_groups, 2)}"
#      },
#       {
#        group = "${element(module.cluster3.instance_groups, 0)}"
#      },
#      {
#        group = "${element(module.cluster3.instance_groups, 1)}"
#      },
#      {
#        group = "${element(module.cluster3.instance_groups, 2)}"
#      },
#    ]
#  }

#  backend_params = [
#   // health check path, port name, port number, timeout seconds.
#    "/,http,30000,10",
#  ]
#}

#module "cluster1_named_port_1" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster1.instance_groups, 0)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster1_named_port_2" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster1.instance_groups, 1)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster1_named_port_3" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster1.instance_groups, 2)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster2_named_port_1" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster2.instance_groups, 0)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster2_named_port_2" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster2.instance_groups, 1)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster2_named_port_3" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster2.instance_groups, 2)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster3_named_port_1" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster3.instance_groups, 0)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster3_named_port_2" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster3.instance_groups, 1)}"
#  name           = "http"
#  port           = "30000"
#}

#module "cluster3_named_port_3" {
#  source         = "github.com/danisla/terraform-google-named-ports"
#  instance_group = "${element(module.cluster3.instance_groups, 2)}"
#  name           = "http"
#  port           = "30000"
#}  
  
output "cluster1-name" {
  value = "${var.region1_cluster_name}"
}

output "cluster2-name" {
  value = "${var.region2_cluster_name}"
}

output "cluster3-name" {
  value = "${var.region3_cluster_name}"
}

  
output "cluster1-region" {
  value = "${var.region1}"
}

output "cluster2-region" {
  value = "${var.region2}"
}

output "cluster3-region" {
  value = "${var.region3}"
}
  
  
#output "load-balancer-ip" {
#  value = "${module.glb.external_ip}"
#}
