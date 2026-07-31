web: bin/rails server
worker: bin/jobs
release: bin/rails db:prepare && bin/rails runner "Model.refresh!"
