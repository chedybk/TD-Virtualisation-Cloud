resource "google_compute_network" "vpc" {
  name = "td-vpc"
  auto_create_subnetworks = true
}


resource "google_compute_subnetwork" "subnet" {
  name          = "td-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_instance" "vm" {
  name         = "td-vm"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }
}


resource "google_sql_database_instance" "db" {
  name                = "td-db"
  database_version    = "POSTGRES_15"
  region              = "europe-west1"
  deletion_protection = false

  settings {
    tier    = "db-f1-micro"
    edition = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

resource "google_dns_managed_zone" "zone" {
  name     = "td-zone"
  dns_name = "example.com."
}


resource "google_dns_record_set" "vm" {
  name         = "app.${google_dns_managed_zone.zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.zone.name
  rrdatas      = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}