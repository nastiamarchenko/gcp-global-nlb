/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
     
resource "google_compute_global_forwarding_rule" "tcp" {
  project    = "${var.project}"
  name       = "${var.name}"
  target     = "${google_compute_target_tcp_proxy.default.self_link}"
  ip_address = "${google_compute_global_address.default.address}"
  port_range = "${var.service_port}"
  depends_on = ["google_compute_global_address.default"]
}   
     
resource "google_compute_target_tcp_proxy" "default" {
  project          = "${var.project}"
  name             = "${var.name}"
  proxy_header     = "PROXY_V1"
  backend_service  = "${google_compute_backend_service.default.self_link}"
}   
   

resource "google_compute_backend_service" "default" {
  project         = "${var.project}"
  count           = "${length(var.backend_params)}"
  name            = "${var.name}-backend-${count.index}"
  port_name       = "${element(split(",", element(var.backend_params, count.index)), 1)}"
  protocol        = "TCP"
  timeout_sec     = 10
  backend         = ["${var.backends["${count.index}"]}"]
  health_checks   = ["${element(google_compute_health_check.default.*.self_link, count.index)}"]
  security_policy = "${var.security_policy}"
}


resource "google_compute_health_check" "default" {
  name               = "health-check"
  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "30000"
    proxy_header = "PROXY_V1"
  }
}



resource "google_compute_global_address" "default" {
  project    = "${var.project}"
  name       = "${var.name}-address"
  ip_version = "${var.ip_version}"
}




# Create firewall rule for each backend in each network specified, uses mod behavior of element().
resource "google_compute_firewall" "default-hc" {
  count         = "${length(var.firewall_networks) * length(var.backend_params)}"
  project       = "${element(var.firewall_projects, count.index) == "default" ? var.project : element(var.firewall_projects, count.index)}"
  name          = "${var.name}-hc-${count.index}"
  network       = "${element(var.firewall_networks, count.index)}"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["${var.target_tags}"]

  allow {
    protocol = "tcp"
    ports    = ["${element(split(",", element(split("|", join("", list(join("|", var.backend_params), replace(format("%*s", length(var.backend_params), ""), " ", "|")))), count.index)), 2)}"]
  }
}
