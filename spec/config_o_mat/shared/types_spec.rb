# frozen_string_literal: true

# Copyright 2021 Teak.io, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'config_o_mat/shared/types'

RSpec.shared_examples 'configuration type equality' do
  it 'is equal to another instance with the same settings' do
    expect(subject).to be == described_class.new(opts)
  end

  it 'is not equal to another instance with different settings' do
    expect(subject).not_to be == described_class.new(opts.merge(difference))
  end

  it 'is not equal to a different type' do
    expect(subject).not_to be == opts
  end
end

RSpec.describe ConfigOMat::Service do
  let(:opts) do
    {
      systemd_unit: systemd_unit, restart_mode: restart_mode, templates: templates
    }
  end

  let(:systemd_unit) { 'test0' }
  let(:restart_mode) { 'restart' }
  let(:templates) { ['templ0'] }

  let(:difference) { { systemd_unit: 'foo' } }

  subject { described_class.new(opts) }

  include_examples 'configuration type equality'

  context 'without any settings' do
    let(:systemd_unit) { nil }
    let(:restart_mode) { nil }
    let(:templates) { nil }

    it 'reports errors' do
      subject.validate
      expect(subject.errors).to match(
        templates: ['must be present', 'must be an array of strings'],
        systemd_unit: ['must be present'],
        restart_mode: ['must be one of [:restart, :flip_flop, :restart_all]']
      )
    end
  end

  context 'when restart_mode=restart' do
    context 'if the systemd_unit ends in @' do
      let(:systemd_unit) { 'test0@' }

      it 'reports errors' do
        subject.validate
        expect(subject.errors).to match(
          systemd_unit: ['must not be a naked instantiated unit when restart_mode=restart']
        )
      end
    end

    context 'if the systemd_unit contains an instance name' do
      let(:systemd_unit) { 'test0@1' }

      it 'is valid' do
        subject.validate
        expect(subject.errors?).to be false
      end
    end
  end

  context 'when restart_mode=restart_all' do
    let(:restart_mode) { 'restart_all' }

    it 'is valid' do
      subject.validate
      expect(subject.errors?).to be false
    end

    it 'appends @ and an escaped * to the systemd_unit' do
      expect(subject.systemd_unit).to eq "#{systemd_unit}@\\x2a"
    end

    context 'if the systemd_unit ends in @' do
      let(:systemd_unit) { 'test@' }

      it 'is valid' do
        subject.validate
        expect(subject.errors?).to be false
      end

      it 'appends an escaped * to the systemd_unit' do
        expect(subject.systemd_unit).to eq "#{systemd_unit}\\x2a"
      end
    end

    context 'if the systemd_unit ends in @\\x2a' do
      let(:systemd_unit) { 'test@\\x2a' }

      it 'is valid' do
        subject.validate
        expect(subject.errors?).to be false
      end

      it 'does not change the systemd_unit' do
        expect(subject.systemd_unit).to eq systemd_unit
      end
    end

    context 'if the systemd_unit contains an instance name' do
      let(:systemd_unit) { 'test0@1' }

      it 'reports errors' do
        subject.validate
        expect(subject.errors).to match(
          systemd_unit: ['must not be an instantiated unit when restart_mode=restart_all']
        )
      end
    end
  end

  context 'when restart_mode=flip_flop' do
    let(:restart_mode) { 'flip_flop' }

    it 'appends @ to the systemd_unit' do
      expect(subject.systemd_unit).to eq "#{systemd_unit}@"
    end

    context 'if the systemd_unit is empty' do
      let(:systemd_unit) { nil }

      it 'reports errors' do
        subject.validate
        expect(subject.errors).to match(
          systemd_unit: ['must be present'],
        )
      end
    end

    context 'if the systemd_unit already ends in @' do
      let(:systemd_unit) { 'test0@' }

      it 'does not modify the systemd_unit' do
        expect(subject.systemd_unit).to eq systemd_unit
      end
    end

    context 'if the systemd_unit contains an instance name' do
      let(:systemd_unit) { 'test@1' }

      it 'reports errors' do
        subject.validate
        expect(subject.errors).to match(
          systemd_unit: ['must not contain an instance (anything after a @)']
        )
      end
    end
  end
end

RSpec.describe ConfigOMat::Template do
  let(:opts) do
    {
      src: src, dst: dst
    }
  end

  let(:src) { 'foo.conf' }
  let(:dst) { 'foo.conf' }

  let(:difference) { { dst: 'bar.conf' } }

  subject { described_class.new(opts) }

  include_examples 'configuration type equality'

  context 'without any settings' do
    let(:src) { nil }
    let(:dst) { nil }

    it 'reports errors' do
      subject.validate
      expect(subject.errors).to match(
        src: ['must be present'],
        dst: ['must be present']
      )
    end
  end
end

RSpec.describe ConfigOMat::Profile do
  let(:opts) do
    {
      application: application, environment: environment, profile: profile
    }
  end

  let(:application) { 'test' }
  let(:environment) { 'test' }
  let(:profile) { 'test' }
  let(:difference) { { application: 'other' } }

  subject { described_class.new(opts) }

  include_examples 'configuration type equality'

  context 'without any settings' do
    let(:application) { nil }
    let(:environment) { nil }
    let(:profile) { nil }

    it 'reports errors' do
      subject.validate
      expect(subject.errors).to match(
        application: ['must be present'],
        environment: ['must be present'],
        profile: ['must be present']
      )
    end
  end
end
