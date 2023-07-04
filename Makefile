CACHIX_NAME = nixpkgs-azerothcore

.PHONY: clean cachix-push

result:
	nix build

cachix-push: result
	nix build --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| cachix push ${CACHIX_NAME}

clean:
	rm result
