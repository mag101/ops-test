node ('master'){
stage ('build') {
sh 'rm -rf /tmp/test'
sh 'git clone https://github.com/mag101/ops-test.git/ /tmp/test'
}
stage ('file test') {
   sh 'test -d /tmp/test/cgi-bin'
}
stage ('Deploy') {
  sh 'scp -r  /tmp/test/cgi-bin ubuntu@$(cat /var/lib/jenkis/swarm-m-ip):cgi-bin' 
  sh 'ssh -q ubuntu@$(cat /var/lib/jenkis/swarm-m-ip) "sudo cp -r /home/ubuntu/cgi-bin /var/www/html/; sudo chmod  +x /var/www/html/cgi-bin/*"' 
  }
}

