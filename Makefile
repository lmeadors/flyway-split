.PHONY: help start stop migrate migrate-admin migrate-dev reset logs psql

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

start: ## Start the database container
	docker-compose up -d db

stop: ## Stop all containers
	docker-compose down

migrate: migrate-admin migrate-dev ## Run both admin and dev migrations in order

migrate-admin: ## Run admin migrations (DBA role: schema, roles, permissions)
	docker-compose run --rm migrate-admin

migrate-dev: ## Run dev migrations (developer role: tables, views, indexes)
	docker-compose run --rm migrate-dev

reset: ## Tear down containers and volumes, then restart the database
	docker-compose down -v
	docker-compose up -d db

logs: ## Tail logs from all containers
	docker-compose logs -f

psql: ## Open a psql shell as the postgres superuser
	docker-compose exec db psql -U postgres bookstore_db
