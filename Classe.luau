type function moveParams(src: type, 
	i: type, j: type, to: type)
	
	--assert(src:is'function'and i:is'singleton'and 
	--	j:is'singleton'and to:is'function')
	
	local i = tonumber(i:value()) or 1
	local j = tonumber(j:value())
	
	local srcParams = src:parameters()
	if not srcParams.head then return to end
	
	local head = table.move(srcParams.head, 
		i, j or #srcParams.head, 1, {})
	
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

type function find(t: type, key: value)
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

type function absent(t1: type, t2: type)
	if not (t1:is'singleton' or t1:is'nil') then return t1 end
	return if not t1:value() then t2 else t
end

type PhantomMeta<A, M, E> = {
	a: A & index<find<E, 'phantomMeta'>, 'a'>,
	m: M & index<find<E, 'phantomMeta'>, 'm'>, 
	e: E
}

type Super<E> = moveParams<index<E, '_init'>
	, '1', nil, () -> ()>

export type Self<M> = index<M, 'a'> & index<M, 'm'>

export type Classe<M> = {
	childs: {any},
	ancestry: {any},
	
	phantomMeta: M,
	meta: {
		__index: index<M, 'm'>,
	},
	
	new: moveParams<find<index<M, 'm'>, 'init'>, 
	'2', nil, () -> Self<M>>,
	
	_init: find<index<M, 'm'>, 'init'>,
}

local Classe = {}

Classe.build = function<M, PM>(meta: M, 
	phtd: PM): Classe<PM>
	
	local init = meta.init
	assert(init, "[Classe]: Init function not found!")
	
	local self = {
		childs = {},
		ancestry = {},
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
	
	function self.new(...: any)
		local obj = {}; init(obj, ...)
		return setmetatable(obj, meta)
	end
	
	return self
end

Classe.meta = function<A, M, E>(attrs: A, meta: M, 
	extends: E): (M, PhantomMeta<A, M, E>, Super<E>)
	
	if extends then
		local extendsIndex = extends.meta.__index
		
		for k, fn in extendsIndex do
			if meta[k] then continue end
			meta[k] = fn
		end
	end
	
	return meta, nil, extends and extends._init
end

return Classe
