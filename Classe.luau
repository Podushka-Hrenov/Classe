type function moveParams(src: type, 
	i: type, j: type, t: type, to: type)
	
	--assert(src:is'function'and i:is'singleton'and 
	--	j:is'singleton'and to:is'function')
	
	local i = tonumber(i:value()) or 1
	local t = tonumber(t:value()) or 1
	local j = tonumber(j:value())
	
	local srcParams = src:parameters()
	if not srcParams.head then return to end
	
	local head = table.move(srcParams.head, 
		i, j or #srcParams.head, t, to:parameters().head or {})
	
	to:setparameters(head, srcParams.tail)
	
	return to
end

type function setproperty(t: type, key: type, value: type)
	--assert((t:is'table' or t:is'intersection') and 
	--	key:is'singleton')
	
	if t:is('intersection') then
		local components = t:components()
		local target: type
		
		for i, comp in components do
			--assert(comp:is'table')
			
			if not comp:readproperty(key) then 
				continue 
			end
			
			target = comp
		end
		
		if not target then target = components[1] end
		target:setproperty(key, value)

		return types.intersectionof(unpack(components))
	end
	
	t:setproperty(key, value)
	
	return t
end

type function find(t: type, key: type)
	if not (t:is'table' or t:is'intersection') then
		return types.any
	end
	
	assert(key:is'singleton')
	
	if t:is('intersection') then
		local components = t:components()
		local target: type
		
		for i, comp in components do
			if not comp:is'table' then continue end
			local read = comp:readproperty(key)
			
			if read then return read end
		end
		
		return types.any
	end
	
	return t:readproperty(key) or types.any
end

type function absent(t1: type, t2: type, t3: type)
	if not (t1:is'singleton' or t1:is'nil' or t1:is'unknown') then return t1 end
	return if t1:is'unknown' or not t1:value() then t2 else not t3:is'nil' and t3 or t1
end

type function elementsTo(t: type, e: type)
	assert(t:is'table' or t:is'intersection')
	
	if t:is'intersection' then
		local components = t:components()
		
		for i, comp in components do
			if not comp:is'table' then continue end
			
			for k in comp:properties() do
				comp:setproperty(k, e)
			end
			
		end
		
		return types.intersectionof(unpack(components))
	end
	
	for k in t:properties() do
		t:setproperty(k, e)
	end
	
	return t
end

type PhantomMeta<A, M, E> = {
	a: A & index<find<E, 'phantomMeta'>, 'a'>,
	m: M & index<find<E, 'phantomMeta'>, 'm'>, 
	e: E
}

type Super<E> = moveParams<index<E, '_init'>
	, '1', nil, '1', () -> ()>

export type Self<M> = index<M, 'a'> & index<M, 'm'>
export type ISelf<M> = elementsTo<index<M, 'a'>, any>

export type Classe<M> = {
	childs: {any},
	overrides: {any},
	
	phantomMeta: M,
	meta: {
		__index: index<M, 'm'>,
	},
	
	new: moveParams<find<index<M, 'm'>, 'init'>, 
	'2', nil, '1', () -> Self<M>>,
	
	_init: find<index<M, 'm'>, 'init'>,
}

local Classe, Cmeta = {}, {}

function Cmeta:__newindex(key: any, value: any)
	rawset(self.meta.__index, key, value)
	
	for i, child in self.childs do
		if child.overrides[key] then continue end
		child.meta.__index[key] = value
	end
end

Classe.build = function<M, PM>(meta: M, 
	phtd: PM, extends: any?): Classe<PM>
	
	local init = meta.init
	assert(init, "Init function not found!")
	
	local self = {
		childs = {},
		overrides = {},
		meta = meta
	}
	
	meta.__index = {}
	meta.init = nil; self._init = init
	
	for name, data in meta do
		if type(name) == 'string' and 
			name:find('^__') then
			
			continue
		end
		
		meta[name] = nil
		meta.__index[name] = data
	end
		
	if extends then
		table.insert(extends.childs, self)
		
		for k, v in extends.meta.__index do
			if not meta[k] then continue end 
			table.insert(self.overrides, k)
		end
	end
	
	function self.new(...: any)
		local obj = {}; init(obj, ...)
		return setmetatable(obj, meta)
	end
	
	return setmetatable(self, Cmeta)
end

Classe.meta = function<A, M, E>(attrs: A, meta: M, 
	extends: E?): (M, PhantomMeta<A, M, E>, Super<E>?)
	
	assert(type(meta)=='table', 'meta must be a table')
	
	if extends then
		for k, fn in extends.meta.__index do
			if meta[k] then continue end
			meta[k] = fn
		end
	end
	
	return meta, nil, extends and extends._init
end

return Classe
