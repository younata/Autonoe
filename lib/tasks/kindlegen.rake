namespace :kindlegen do

  namespace :download do
    desc 'Download Kindlegen for linux'
    task :linux do
      `mkdir -p kindlegen`
      `wget http://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz && tar -xzf kindlegen_linux_2.6_i386_v2_9.tar.gz -C kindlegen && cp kindlegen/kindlegen bin/kindleGen`
      `rm kindlegen_linux_2.6_i386_v2_9.tar.gz`
      `rm -rf kindlegen`
    end

    desc 'Download Kindlegen for mac'
    task :mac do
      `wget http://kindlegen.s3.amazonaws.com/KindleGen_Mac_i386_v2_9.zip && unzip KindleGen_Mac_i386_v2_9.zip -d kindlegen && cp kindlegen/kindleGen bin/kindleGen`
      `rm KindleGen_Mac_i386_v2_9.zip`
      `rm -rf kindlegen`
    end
  end
end
