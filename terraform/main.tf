provider "google" {
  project = "cloudops-vault-lab"
  region  = "europe-west1"
}

resource "google_compute_network" "vpc" {
  name                    = "cloudops-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_app" {
  name          = "subnet-app"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet_db" {
  name          = "subnet-db"
  ip_cidr_range = "10.0.2.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_instance" "vault_server" {
  name         = "vault-server"
  machine_type = "e2-small"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_app.id
    access_config {}
  }

  tags = ["vault-server", "ssh-allowed"]
}

resource "google_compute_instance" "app_server" {
  name         = "app-server"
  machine_type = "e2-small"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_app.id
    access_config {}
  }

  tags = ["app-server", "ssh-allowed"]
}

resource "google_compute_instance" "db_server" {
  name         = "db-server"
  machine_type = "e2-small"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_db.id
    access_config {}
  }

  tags = ["db-server", "ssh-allowed"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}

resource "google_compute_firewall" "deny_all_ingress" {
  name      = "deny-all-ingress"
  network   = google_compute_network.vpc.id
  priority  = 65534
  direction = "INGRESS"

  deny { protocol = "all" }

  source_ranges = ["0.0.0.0/0"]
}
