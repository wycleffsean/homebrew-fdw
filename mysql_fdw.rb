# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class MysqlFdw < Formula
  desc "PostgreSQL foreign data wrapper for MySQL"
  homepage "https://github.com/EnterpriseDB/mysql_fdw"
  url "https://github.com/EnterpriseDB/mysql_fdw/archive/refs/tags/REL-2_9_1.tar.gz"
  version "2.9.1"
  sha256 "26e8dc2012de6151450fbf2a5cd591a3d5b8a52b1e3ec0600b14a4a6b4a06b54"
  license "NOASSERTION"

  depends_on "mysql"
  depends_on "postgresql"

  def postgresql_formula
    @postgresql_formula ||= Formula["postgresql"]
  end

  def postgresql_lib
    # Follow the PostgreSQL linked keg back to the active Postgres installation
    # as it is common for people to avoid upgrading Postgres.
    postgresql_formula.opt_lib.realpath / postgresql_formula.name
  end

  def postgresql
    postgresql_formula.linked_keg.realpath
  end

  def mysql_lib
    Formula["mysql"].opt_lib.realpath
  end

  def install
    ENV.append("USE_PGXS", "1")

    # Remove unrecognized options if they cause configure to fail
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    # system "./configure", "--disable-silent-rules", *std_configure_args

    before = %q[PG_CPPFLAGS += -D _MYSQL_LIBNAME=\"lib$(MYSQL_LIB)$(DLSUFFIX)\"]
    after = %q[PG_CPPFLAGS += -D _MYSQL_LIBNAME=\"#{mysql_lib}/lib$(MYSQL_LIB)$(DLSUFFIX)\"]
    inreplace "Makefile", before, after

    system "make"
    mkdir "stage"
    system "make", "install"#, "DESTDIR=#{buildpath}/stage"

    # libmysqlclient.dylib must go in the following directory:
    # pg_config --pkglibdir

=begin
    # actual path
    mysql_client_library = (mysql_lib / "libmysqlclient.dylib")

    # mysql_fdw includes the PGXS makefiles and so will install __everything__
    # into the Postgres keg instead of the mysql_fdw keg. Unfortunately, some
    # things have to be inside the Postgres keg in order to be function. So, we
    # install everything to a staging directory and manually move the pieces
    # into the appropriate prefixes.

    so = Dir["stage/**/*.so"]#, mysql_client_library]
    extensions = Dir["stage/**/extension/*"]

    postgresql_lib.install so

    # Install extension scripts to the Postgres keg.
    # `CREATE EXTENSION mysql_fdw;` won't work if these are located elsewhere.
    (postgresql/"share/postgresql/extension").install extensions
=end
  end

  test do
    # dlopen(libmysqlclient.dylib, 0x0001): tried: 'libmysqlclient.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OSlibmysqlclient.dylib' (no such file), '/usr/lib/libmysqlclient.dylib' (no such file, not in dyld cache), 'libmysqlclient.dylib' (no such file)

    ENV.append("USE_PGXS", "1")
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test mysql_fdw`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "make", "installcheck"
  end
end
