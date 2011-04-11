Illiad::Base.establish_connection(
  :dataserver => Source::Illiad::CONFIG['db']['dataserver'],
  :adapter    => Source::Illiad::CONFIG['db']['adapter'],
  :host       => Source::Illiad::CONFIG['db']['host'],
  :dsn        => Source::Illiad::CONFIG['db']['dsn'],
  :username   => Source::Illiad::CONFIG['db']['username'],
  :password   => Source::Illiad::CONFIG['db']['password'],
  :database   => Source::Illiad::CONFIG['db']['database']
)
