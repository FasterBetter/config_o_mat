# frozen_string_literal: true

require 'lifecycle/vm_memory'

require 'configurator_types'

class ConfiguratorMemory < Lifecycle::VmMemory
  attr_accessor :argv, :env, :early_exit, :configuration_directory,
                :runtime_directory, :logs_directory, :run_count, :profile_defs,
                :template_defs, :service_defs, :dependencies, :refresh_interval,
                :client_id, :compiled_templates

  def initialize(
    argv: [],
    env: {},
    early_exit: false,
    configuration_directory: nil,
    runtime_directory: nil,
    logs_directory: nil,
    run_count: 0,
    profile_defs: {},
    template_defs: {},
    service_defs: {},
    dependencies: {},
    refresh_interval: 5,
    client_id: '',
    logger: nil,
    compiled_templates: {}
  )
    super()

    @argv = argv
    @env = env
    @early_exit = early_exit
    @configuration_directory = configuration_directory
    @runtime_directory = runtime_directory
    @logs_directory = logs_directory
    @run_count = run_count
    @profile_defs = profile_defs
    @template_defs = template_defs
    @service_defs = service_defs
    @dependencies = dependencies
    @refresh_interval = refresh_interval
    @client_id = client_id
    @logger = logger
    @compiled_templates = compiled_templates
  end
end
