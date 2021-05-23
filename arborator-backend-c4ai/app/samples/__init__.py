BASE_ROUTE = "projects" # because samples is nested in project


def register_routes(api, app, root="api"):
    from .controller import api as project_api

    api.add_namespace(project_api, path=f"/{root}/{BASE_ROUTE}")