namespace :kindlegen do
  desc "Download Kindlegen"
  task :download do
    `mkdir -p kindlegen`
    `wget http://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz && tar -xzf kindlegen_linux_2.6_i386_v2_9.tar.gz -C kindlegen && cp kindlegen/kindlegen bin/kindleGen`
    `rm kindlegen_linux_2.6_i386_v2_9.tar.gz`
    `rm -rf kindlegen`
  end
end
