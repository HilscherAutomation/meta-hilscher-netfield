# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS         =
SPHINXBUILD_PREFIX =
ifneq ($(HOSTNAME), sphinxdoc)
	SPHINXBUILD_PREFIX = _docker/start_dockerenv.sh
endif
SPHINXBUILD        = $(SPHINXBUILD_PREFIX) sphinx-build
SOURCEDIR          = ./
BUILDDIR           = _sphinx-build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	./create_platform_docs.sh
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
