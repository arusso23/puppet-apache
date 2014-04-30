require 'spec_helper'

describe( 'apache::service', :type => :class ) do
  let(:redhat_facts) {{ 'osfamily' => 'RedHat' }}
  let(:redhat6_facts) {{'operatingsystemrelease' => '6.5' }.merge(redhat_facts)}
  let(:redhat5_facts) {{'operatingsystemrelease' => '5.10'}.merge(redhat_facts)}

  context "on Red Hat" do
    context "Version 5" do
      let(:facts) { redhat5_facts }
      it do
        should contain_service('httpd').with({
          'ensure' => 'running',
          'name' => 'httpd',
          'enable' => true,
          'require' => 'Class[Apache::Config]',
        })
      end
    end
    context "Version 6" do
      let(:facts) { redhat6_facts }
      it do
        should contain_service('httpd').with({
          'ensure' => 'running',
          'name' => 'httpd',
          'enable' => true,
          'require' => 'Class[Apache::Config]',
        })
      end
    end
  end
end