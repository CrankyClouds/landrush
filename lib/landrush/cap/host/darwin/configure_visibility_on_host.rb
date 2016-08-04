module Landrush
  module Cap
    module Darwin
      class ConfigureVisibilityOnHost
        class << self
          attr_writer :sudo, :config_dir

          def configure_visibility_on_host(env, _ip, tld)
            @env = env
            @tld = tld
            if contents_match?
              info 'Host DNS resolver config looks good.'
            else
              info 'Need to configure the host.'
              write_config!
            end
          end

          private

          def sudo
            @sudo ||= 'sudo'
          end

          def config_dir
            @config_dir ||= Pathname('/etc/resolver')
          end

          def info(msg)
            @env.ui.info("[landrush] #{msg}") unless @env.nil?
          end

          def desired_contents
            <<-EOS.gsub(/^            /, '')
            # Generated by landrush, a vagrant plugin
            nameserver 127.0.0.1
            port #{Server.port}
            EOS
          end

          def config_file
            config_dir.join(@tld)
          end

          def contents_match?
            config_file.exist? && File.read(config_file) == desired_contents
          end

          def write_config!
            info 'Momentarily using sudo to put the host config in place...'
            system "#{sudo} mkdir #{config_dir}" unless config_dir.directory?
            Tempfile.open('vagrant_landrush_host_config') do |f|
              f.write(desired_contents)
              f.close
              system "#{sudo} cp #{f.path} #{config_file}"
              system "#{sudo} chmod 644 #{config_file}"
            end
          end
        end
      end
    end
  end
end
