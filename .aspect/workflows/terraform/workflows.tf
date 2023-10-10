data "google_compute_image" "runner_image" {
  # Aspect's GCP aspect-workflows-images project provides public Aspect Workflows GCP images for
  # getting started during the trial period. We recommend that all Workflows users build their own
  # GCP images and keep up-to date with patches. See
  # https://docs.aspect.build/v/workflows/install/packer for more info and/or
  # https://github.com/aspect-build/workflows-images for example packer scripts and BUILD targets
  # for building GCP images for Workflows.
  project = "aspect-workflows-images"
  name    = "aspect-workflows-ubuntu-2304-kitchen-sink-1-5-0"
}

module "aspect_workflows" {
  # Project & region configuration. This is optional. Alternately, you may configure a global
  # provider project & region and the Workflows module will default to that.
  project = local.project
  region  = local.region

  # Aspect Workflows terraform module
  source = "https://s3.us-east-2.amazonaws.com/static.aspect.build/aspect/5.8.0/workflows-gcp/terraform-gcp-aspect-workflows.zip"

  # Network properties
  network    = google_compute_network.workflows_network.id
  subnetwork = google_compute_subnetwork.workflows_subnet.id

  # Number of nodes & machine type in the kubernetes cluster where the remote cache & observability
  # services run.
  k8s_cluster = {
    node_count   = 3
    machine_type = "e2-standard-2"
  }

  # Remote cache configuration
  remote = {
    cache_shards           = 3
    cache_size_gb          = 384
    load_balancer_replicas = 2
    replicate_cache        = false
  }

  # CI properties
  hosts = ["bk"]

  # Warming set definitions
  warming_sets = {
    default  = {}
  }

  # Resource types for use by runner groups
  resource_types = {
    default = {
      # Aspect Workflows requires machine types that have local SSD drives. See
      # https://cloud.google.com/compute/docs/machine-resource#machine_type_comparison for full list
      # of machine types availble on GCP.
      machine_type    = "n1-standard-4"
      image_id        = data.google_compute_image.runner_image.id
      use_preemptible = true
    }
  }

  # Buildkite runner group definitions
  bk_runner_groups = {
    # The default runner group is use for the main build & test workflows.
    default = {
      agent_idle_timeout_min    = 1
      max_runners               = 10
      min_runners               = 0
      queue                     = "aspect-default"
      resource_type             = "default"
      scaling_polling_frequency = 3 # check for queued jobs every 20s
      warming                   = true
    }
    # The warming runner group is used for the periodic warming job that creates
    # warming archives for use by other runner groups.
    warming = {
      agent_idle_timeout_min = 1
      max_runners            = 1
      min_runners            = 0
      queue                  = "aspect-warming"
      resource_type          = "default"
    }
  }

  # This varies by each customer. This one is dedicated to rules_js.
  pagerduty_integration_key = "6c16035a05834405d0920f74b4b326c5"
}
