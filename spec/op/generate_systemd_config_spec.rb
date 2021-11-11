# frozen_string_literal: true

require 'op/generate_systemd_config'

require 'meta_configurator_memory'
require 'meta_configurator_types'
require 'configurator_types'

require 'tmpdir'

RSpec.describe Op::GenerateSystemdConfig do
  def perform
    described_class.call(state)
  end

  before do
    @systemd_directory = Dir.mktmpdir
    @result = perform
  end

  after do
    FileUtils.remove_entry @systemd_directory
  end

  subject(:result) { @result }

  let(:state) do
    MetaConfiguratorMemory.new(
      template_defs: template_defs,
      service_defs: service_defs,
      runtime_directory: runtime_directory,
      systemd_directory: systemd_directory,
      systemd_interface: systemd_interface
    )
  end

  let(:template_defs) do
    {
      templ0: Template.new(src: 'foo.conf', dst: 'foo.conf'),
      templ1: Template.new(src: 'bar.conf', dst: 'bar.conf')
    }
  end

  let(:service_defs) do
    {
      test0: Service.new(
        systemd_unit: 'test0', restart_mode: 'restart', templates: [
          'templ0', 'templ1'
        ]
      ),
      test1: Service.new(
        systemd_unit: 'test1', restart_mode: 'restart', templates: [
          'templ0'
        ]
      )
    }
  end

  let(:systemd_directory) { @systemd_directory }
  let(:runtime_directory) { '/somewhere/else' }
  let(:systemd_interface) do
    instance_double("SystemdInterface").tap do |iface|
      allow(iface).to receive(:enable_restart_paths).and_return(nil)
      allow(iface).to receive(:daemon_reload).and_return(nil)
    end
  end

  it 'enables restart paths for each service' do
    expect(systemd_interface).to have_received(:enable_restart_paths).with(['test0', 'test1'])
  end

  it 'outputs additional configuration' do
    expect(File.read(File.join(systemd_directory, 'test0.service.d/99_teak_configurator.conf'))).to include(
      %([Service]\nLoadCredential=foo.conf:#{runtime_directory}/foo.conf\nLoadCredential=bar.conf:#{runtime_directory}/bar.conf)
    )
    expect(File.read(File.join(systemd_directory, 'test1.service.d/99_teak_configurator.conf'))).to include(
      %([Service]\nLoadCredential=foo.conf:#{runtime_directory}/foo.conf)
    )
  end

  it 'reloads the daemon' do
    expect(systemd_interface).to have_received(:daemon_reload)
  end
end