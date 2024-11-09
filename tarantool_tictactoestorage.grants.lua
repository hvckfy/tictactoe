box.schema.user.create('user',{password='password', if_not_exists = true})
box.schema.user.grant('user','read,write,execute,create,drop','universe',nil,{if_not_exists=true})
-- change user and password 