data "google_compute_image" "runner_image" {
  # Aspect's GCP aspect-workflows-images project provides public Aspect Workflows GCP images for
  # getting started during the trial period. We recommend that all Workflows users build their own
  # GCP images and keep up-to date with patches. See
  # https://docs.aspect.build/workflows/install/packer for more info and/or
  # https://github.com/aspect-build/workflows-images for example packer scripts and BUILD targets
  # for building GCP images for Workflows.
  project = "aspect-workflows-images"
  name    = "aspect-workflows-ubuntu-2304-kitchen-sink-amd64-1-6-0"
}

module "aspect_workflows" {
  # Project & region configuration. This is optional. Alternately, you may configure a global
  # provider project & region and the Workflows module will default to that.
  project = local.project
  region  = local.region

  # Aspect Workflows terraform module
  source = "https://s3.us-east-2.amazonaws.com/static.aspect.build/aspect/5.9.0-rc.9/workflows-gcp/terraform-gcp-aspect-workflows.zip"

  # Network properties
  network    = google_compute_network.workflows_network.id
  subnetwork = google_compute_subnetwork.workflows_subnet.id

  # Number of nodes & machine type in the kubernetes cluster where the remote cache & observability
  # services run.
  k8s_cluster = {
    node_count   = 3
    machine_type = "e2-standard-2"
  }

  # Delivery properties
  delivery_enabled = true

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
    default = {}
  }

  # Resource types for use by runner groups. Aspect recommends machines types that have SSD drives
  # for large Bazel workflows. See
  # https://cloud.google.com/compute/docs/machine-resource#machine_type_comparison for list of
  # machine types availble on GCP.
  resource_types = {
    default = {
      machine_type = "n1-standard-4"
      image_id     = data.google_compute_image.runner_image.id
      # While preemtible instances are possible to provision and we use them here on this open source
      # repository as a demonstration of how to reduce compute costs, they are not recommended for
      # repositories where the occasional CI failures due to a machine being preemted mid-job are not
      # acceptable.
      use_preemptible = true
    }
    small = {
      machine_type = "e2-medium"
      num_ssds     = 0
      image_id     = data.google_compute_image.runner_image.id
      # While preemtible instances are possible to provision and we use them here on this open source
      # repository as a demonstration of how to reduce compute costs, they are not recommended for
      # repositories where the occasional CI failures due to a machine being preemted mid-job are not
      # acceptable.
      use_preemptible = true
    }
    micro = {
      machine_type = "e2-small"
      num_ssds     = 0
      image_id     = data.google_compute_image.runner_image.id
      # While preemtible instances are possible to provision and we use them here on this open source
      # repository as a demonstration of how to reduce compute costs, they are not recommended for
      # repositories where the occasional CI failures due to a machine being preemted mid-job are not
      # acceptable.
      use_preemptible = true
    }
  }

  # Buildkite runner group definitions
  bk_runner_groups = {
    # The default runner group is use for the main build & test workflows.
    default = {
      agent_idle_timeout_min    = 1
      git_clone_depth           = 64
      max_runners               = 10
      min_runners               = 0
      queue                     = "aspect-default"
      resource_type             = "default"
      scaling_polling_frequency = 3 # check for queued jobs every 20s
      warming                   = true
    }
    small = {
      agent_idle_timeout_min    = 1
      git_clone_depth           = 64
      max_runners               = 20
      min_runners               = 0
      queue                     = "aspect-small"
      resource_type             = "small"
      scaling_polling_frequency = 3     # check for queued jobs every 20s
      warming                   = false # don't warm for faster bootstrap; these runners won't be running large builds
    }
    micro = {
      agent_idle_timeout_min    = 60 * 12
      git_clone_depth           = 64
      max_runners               = 10
      min_runners               = 0
      queue                     = "aspect-micro"
      resource_type             = "micro"
      scaling_polling_frequency = 3     # check for queued jobs every 20s
      warming                   = false # don't warm for faster bootstrap; these runners won't be running large builds
    }
    # The warming runner group is used for the periodic warming job that creates
    # warming archives for use by other runner groups.
    warming = {
      agent_idle_timeout_min = 1
      git_clone_depth        = 1
      max_runners            = 1
      min_runners            = 0
      queue                  = "aspect-warming"
      resource_type          = "default"
    }
  }

  # This varies by each customer. This one is dedicated to rules_js.
  pagerduty_integration_key = "6c16035a05834405d0920f74b4b326c5"
}
