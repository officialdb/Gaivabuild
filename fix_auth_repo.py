with open('lib/features/auth/auth_repository.dart', 'r') as f:
    content = f.read()

old_block = """    await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      if (fullName != null) 'full_name': fullName,
    });"""

new_block = """    final reqBody = {'email': email, 'password': password};
    if (fullName != null) reqBody['full_name'] = fullName;
    await _api.post('/auth/register', body: reqBody);"""

content = content.replace(old_block, new_block)

with open('lib/features/auth/auth_repository.dart', 'w') as f:
    f.write(content)
