class Rabbitmq < Formula
  desc "Messaging and streaming broker"
  homepage "https://www.rabbitmq.com"
  url "https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.3/rabbitmq-server-generic-unix-3.13.3.tar.xz"
  sha256 "ebd7ef9625c5beb1d16d774467489b96b6b637c2fdf1026b5e90a6d56159b4c5"
  license "MPL-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, all: "83a588cb5e31a6fd33d21c10d4622caa028b8a8986b7f472cc4128219d531e7f"
  end

  depends_on "erlang"

  uses_from_macos "python" => :build

  def install
    # Install the base files
    prefix.install Dir["*"]

    # Setup the lib files
    (var/"lib/rabbitmq").mkpath
    (var/"log/rabbitmq").mkpath

    # Correct SYS_PREFIX for things like rabbitmq-plugins
    erlang = Formula["erlang"]
    inreplace sbin/"rabbitmq-defaults" do |s|
      s.gsub! "SYS_PREFIX=${RABBITMQ_HOME}", "SYS_PREFIX=#{HOMEBREW_PREFIX}"
      s.gsub! "CLEAN_BOOT_FILE=start_clean", "CLEAN_BOOT_FILE=#{erlang.opt_lib/"erlang/bin/start_clean"}"
      s.gsub! "SASL_BOOT_FILE=start_sasl", "SASL_BOOT_FILE=#{erlang.opt_lib/"erlang/bin/start_clean"}"
    end

    # Set RABBITMQ_HOME in rabbitmq-env
    inreplace sbin/"rabbitmq-env",
              'RABBITMQ_HOME="$(rmq_realpath "${RABBITMQ_SCRIPTS_DIR}/..")"',
              "RABBITMQ_HOME=#{prefix}"

    # Create the rabbitmq-env.conf file
    rabbitmq_env_conf = etc/"rabbitmq/rabbitmq-env.conf"
    rabbitmq_env_conf.write rabbitmq_env unless rabbitmq_env_conf.exist?

    # Enable plugins - management web UI; STOMP, MQTT, AMQP 1.0 protocols
    enabled_plugins_path = etc/"rabbitmq/enabled_plugins"
    unless enabled_plugins_path.exist?
      enabled_plugins_path.write "[rabbitmq_management,rabbitmq_stomp,rabbitmq_amqp1_0," \
                                 "rabbitmq_mqtt,rabbitmq_stream]."
    end

    sbin.install prefix/"plugins/rabbitmq_management-#{version}/priv/www/cli/rabbitmqadmin"
    (sbin/"rabbitmqadmin").chmod 0755
    generate_completions_from_executable(sbin/"rabbitmqadmin", "--bash-completion", shells: [:bash],
                                         base_name: "rabbitmqadmin", shell_parameter_format: :none)
  end

  def caveats
    <<~EOS
      Management UI: http://localhost:15672
      Homebrew-specific docs: https://rabbitmq.com/install-homebrew.html
    EOS
  end

  def rabbitmq_env
    <<~EOS
      CONFIG_FILE=#{etc}/rabbitmq/rabbitmq
      NODE_IP_ADDRESS=127.0.0.1
      NODENAME=rabbit@localhost
      RABBITMQ_LOG_BASE=#{var}/log/rabbitmq
      PLUGINS_DIR="#{opt_prefix}/plugins:#{HOMEBREW_PREFIX}/share/rabbitmq/plugins"
    EOS
  end

  service do
    run opt_sbin/"rabbitmq-server"
    log_path var/"log/rabbitmq/std_out.log"
    error_log_path var/"log/rabbitmq/std_error.log"
    # need erl in PATH
    environment_variables PATH:          "#{HOMEBREW_PREFIX}/sbin:/usr/sbin:/usr/bin:/bin:#{HOMEBREW_PREFIX}/bin",
                          CONF_ENV_FILE: etc/"rabbitmq/rabbitmq-env.conf"
  end

  test do
    ENV["RABBITMQ_MNESIA_BASE"] = testpath/"var/lib/rabbitmq/mnesia"
    pid = fork { exec sbin/"rabbitmq-server" }
    system sbin/"rabbitmq-diagnostics", "wait", "--pid", pid
    system sbin/"rabbitmqctl", "status"
    system sbin/"rabbitmqctl", "stop"
  end
end
