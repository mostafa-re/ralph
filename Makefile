TEST?=ralph
TEST_ARGS=
DOCKER_REPO_NAME?="allegro"
RALPH_VERSION=$(./get_version.sh)
RALPH_DIR=/opt/ralph

.PHONY: test flake clean coverage docs coveralls run cleanup commit-changelog-tag build-release-package build-snapshot-package

# cleanup the whole middle files, builds and docker images during build proccess.
cleanup:
	rm -rdf build/ debian/files debian/ralph-core src/ralph.egg-info \
	debian/.debhelper/ debian/*debhelper* debian/*.substvars \
	bower_components/ node_modules/ pip_cache/ \
	debian/.changelog.swp ./package-lock.json
	docker image rm --force ralph-deb-packer:latest 2>/dev/null

# commit-changelog-tag is used to publish the new version of the package.
# It commits the generated debian changelog for release/snapshot builds
# and tags the created commit with the next appropriate release version.
commit-changelog-tag:
	git add debian/changelog
	NEXT_VERSION = $(./get_version.sh generate)
	git commit -m "Updated changelog for version $(NEXT_VERSION)"
	git tag $(NEXT_VERSION)

# build-release-package generates a release changelog and uses it to
# build release version of the package. It is mainly used for testing.
build-release-package:
	docker build -f docker/Dockerfile-deb-packer -t ralph-deb-packer:latest .
	docker run --rm -v $(shell pwd):${RALPH_DIR} --network="host" -t ralph-deb-packer:latest release

# build-snapshot-package generates a snapshot changelog and uses it to
# build snapshot version of the package. It is mainly used for testing.
build-snapshot-package:
	docker build -f docker/Dockerfile-deb-packer -t ralph-deb-packer:latest .
	docker run --rm -v $(shell pwd):${RALPH_DIR} --network="host" -t ralph-deb-packer:latest snapshot

build-docker-image:
	docker build \
		--no-cache \
		-f docker/Dockerfile-prod \
		--build-arg RALPH_VERSION="$(RALPH_VERSION)" \
		-t $(DOCKER_REPO_NAME)/ralph:latest \
		-t "$(DOCKER_REPO_NAME)/ralph:$(RALPH_VERSION)" .
	docker build \
		--no-cache \
		-f docker/Dockerfile-static \
		--build-arg RALPH_VERSION="$(RALPH_VERSION)" \
		-t $(DOCKER_REPO_NAME)/ralph-static-nginx:latest \
		-t "$(DOCKER_REPO_NAME)/ralph-static-nginx:$(RALPH_VERSION)" .

build-snapshot-docker-image: build-snapshot-package
	docker build \
		-f docker/Dockerfile-prod \
		--build-arg RALPH_VERSION="$(RALPH_VERSION)" \
		--build-arg SNAPSHOT="1" \
		-t $(DOCKER_REPO_NAME)/ralph:latest \
		-t "$(DOCKER_REPO_NAME)/ralph:$(RALPH_VERSION)" .
	docker build \
		-f docker/Dockerfile-static \
		--build-arg RALPH_VERSION="$(RALPH_VERSION)" \
		-t "$(DOCKER_REPO_NAME)/ralph-static-nginx:$(RALPH_VERSION)" .

publish-docker-image: build-docker-image
	docker push $(DOCKER_REPO_NAME)/ralph:$(RALPH_VERSION)
	docker push $(DOCKER_REPO_NAME)/ralph:latest
	docker push $(DOCKER_REPO_NAME)/ralph-static-nginx:$(RALPH_VERSION)
	docker push $(DOCKER_REPO_NAME)/ralph-static-nginx:latest

publish-docker-snapshot-image: build-snapshot-docker-image
	docker push $(DOCKER_REPO_NAME)/ralph:$(RALPH_VERSION)
	docker push $(DOCKER_REPO_NAME)/ralph-static-nginx:$(RALPH_VERSION)

install-js:
	npm install
	./node_modules/.bin/gulp

js-hint:
	find src/ralph|grep "\.js$$"|grep -v vendor|xargs ./node_modules/.bin/jshint;

install: install-js
	pip3 install -r requirements/prod.txt

install-test:
	pip3 install -r requirements/test.txt

install-dev:
	pip3 install -r requirements/dev.txt

install-docs:
	pip3 install -r requirements/docs.txt

isort:
	isort --diff --recursive --check-only --quiet src

test: clean
	test_ralph test $(TEST) $(TEST_ARGS)

flake: isort
	flake8 src/ralph
	flake8 src/ralph/settings --ignore=F405 --exclude=*local.py
	@cat scripts/flake.txt

clean:
	find . -name '*.py[cod]' -exec rm -rf {} \;

coverage: clean
	coverage run $(shell which test_ralph) test $(TEST) -v 2 --keepdb --settings="ralph.settings.test"
	coverage report

docs: install-docs
	mkdocs build

run:
	dev_ralph runserver_plus 0.0.0.0:8000

menu:
	ralph sitetree_resync_apps

translate_messages:
	ralph makemessages -a

compile_messages:
	ralph compilemessages
