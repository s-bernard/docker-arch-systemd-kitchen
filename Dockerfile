FROM archlinux:latest
MAINTAINER Samuel Bernard "samuel.bernard@gmail.com"

# WORKAROUND for glibc 2.33 and old Docker
# See https://github.com/actions/virtual-environments/issues/2658
# Thanks to https://github.com/lxqt/lxqt-panel/pull/1562
RUN patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst && \
    curl -LO "https://repo.archlinuxcn.org/x86_64/$patched_glibc" && \
    bsdtar -C / -xvf "$patched_glibc"

# Let's run stuff
RUN \
  # First, update everything (start by keyring and pacman)
  pacman -Sy && \
  pacman -S archlinux-keyring --noconfirm --noprogressbar --quiet && \
  pacman -S pacman --noconfirm --noprogressbar --quiet && \
  pacman-db-upgrade && \
  pacman -Su --noconfirm --noprogressbar --quiet && \
  # Install useful packages
  pacman -S sudo systemd tar --noconfirm --noprogressbar --quiet && \
  # Install what is needed for building native extensions
  pacman -S gcc make sed awk gzip grep --noconfirm --noprogressbar --quiet && \
  pacman -S autoconf automake --noconfirm --noprogressbar --quiet && \
  # Install Ruby
  pacman -S ruby --noconfirm --noprogressbar --quiet && \
  # Install useful tools
  pacman -S vim tree iproute2 --noconfirm --noprogressbar --quiet && \
  # Install Chef from gems
  gem install chef chef-bin --no-user-install --no-document && \
  # Fake gem installation in chef directory
  mkdir -p /opt/chef/embedded/bin/ && \
  ln -s /usr/bin/gem /opt/chef/embedded/bin/gem && \
  # Generate locale en_US (workaround for a strange bug in berkshelf)
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
  locale-gen && \
  # Time to clean
  pacman -Rs gcc make --noconfirm --noprogressbar && \
  pacman -Scc --noconfirm --noprogressbar --quiet && \
  # Mask systemd units which will fail
  systemctl mask tmp.mount systemd-tmpfiles-setup.service && \
  # Because systemd is not installed in the same path across distributions
  # The /sbin/init link may or may not be provided by the base image
  if [ ! -e /sbin/init ]; then ln -s /lib/systemd/systemd /sbin/init; fi

RUN \
  # Installing Busser
  GEM_HOME="/tmp/verifier/gems" \
  GEM_PATH="/tmp/verifier/gems" \
  GEM_CACHE="/tmp/verifier/gems/cache" \
  gem install busser --no-document \
    --no-format-executable -n /tmp/verifier/bin --no-user-install && \
  # Busser plugins
  GEM_HOME="/tmp/verifier/gems" \
  GEM_PATH="/tmp/verifier/gems" \
  GEM_CACHE="/tmp/verifier/gems/cache" \
  gem install busser-serverspec serverspec --no-document --no-user-install

ENV LANG=en_US.UTF-8
VOLUME ["/sys/fs/cgroup", "/run"]
CMD  ["/usr/lib/systemd/systemd"]
