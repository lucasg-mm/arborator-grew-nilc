// default user state
export default () => ({
  loginSuccess: false,
  loginError: false,
  failedAccess: false,
  avatarKey: 0,

  as_json: null,
  auth_provider: null,
  created_date: null,
  family_name: null,
  first_name: null,
  get_id: null,
  get_or_create: null,
  id: null,
  is_active: false,
  is_anonymous: true,
  is_authenticated: false,
  last_seen: null,
  make_unique_nickname: null,
  make_valid_nickname: null,
  picture_url: null,
  query: null,
  query_class: null,
  super_admin: false,
  username: null,
});
