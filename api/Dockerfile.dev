# specify the base image
FROM ocaml/opam:ubuntu-20.10-ocaml-4.10

# defines the user as the root
USER root

# defines a work directory
WORKDIR /usr/app

# copies files
COPY . .

# installs ocsigen
RUN opam depext ocsigen-start
RUN opam install ocsigen-start

# installs grew
RUN opam remote add grew "http://opam.grew.fr"
RUN opam install grew grewpy
RUN opam install fileutils

# default command
CMD ["make", "test.byte"]