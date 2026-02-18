local Types = require(script.Types)

type Meta<A, M, E> = setmetatable<M, {
	a: A & index<Types.find<E, 'phantomMeta'>, 'a'>,
	m: M & index<Types.find<E, 'phantomMeta'>, 'm'>, 
	e: E
}>

type Super<E> = Types.moveParams<index<E, '_init'>
	, '1', nil, '1', () -> ()>

export type Self<M> = index<getmetatable<M>, 'a'>
	& index<getmetatable<M>, 'm'>

export type ISelf<M> = Types.elementsTo<
	index<getmetatable<M>, 'a'>, any>

export type Classe<M> = {
	childs: {[number]: any},
	overrides: Types.table,
	
	phantomMeta: getmetatable<M>,
	meta: {
		__index: index<getmetatable<M>, 'm'>,
	},
	
	new: Types.moveParams<Types.find<
		index<getmetatable<M>, 'm'>, 'init'>, 
	'2', nil, '1', () -> Types.sortTable<Self<M>, '^_'>>,
	
	_init: Types.find<index<
		getmetatable<M>, 'm'>, 'init'>,
}

local Classe, Cmeta = {}, {}

function Cmeta:__newindex(key: any, value: any)
	rawset(self.meta.__index, key, value)
	
	for i, child in self.childs do
		if child.overrides[key] then continue end
		child.meta.__index[key] = value
	end
end

Classe.build = function<M>(meta: M): Classe<M>
	assert(type(meta)=='table', 'Meta must be a table')
	
	local init = meta.init
	assert(init, "Init function not found!")
	
	local self = {
		childs = {},
		overrides = {},
		meta = meta
	}
	
	meta.__index = {}
	meta.init = nil; self._init = init
	
	for index, data in meta do
		if type(index) == 'string' and 
			index:find('^__') then
			
			continue
		end
		
		meta[index] = nil
		meta.__index[index] = data
	end
	
	local extends = getmetatable(meta).e
	setmetatable(meta, nil)
		
	if extends then
		table.insert(extends.childs, self)
		
		for k, v in extends.meta.__index do
			if not meta[k] then continue end 
			self.overrides[k] = true
		end
	end
	
	function self.new(...: any)
		local obj = {}; init(obj, ...)
		return setmetatable(obj, meta)
	end
	
	return setmetatable(self, Cmeta)
end

local metaMetatable = {
	__newindex = function() error() end
}

Classe.meta = function<A, M, E>(attrs: A, meta: M, 
	extends: E?): (Meta<A, M, E>, Super<E>?)
	
	assert(type(meta)=='table', 'Meta must be a table')
	
	if extends then
		assert(type(extends)=='table',
			'Extender must be a table')
		
		for k, fn in extends.meta.__index do
			if meta[k] then continue end
			meta[k] = fn
		end
	end
	
	setmetatable(meta, setmetatable({
		e = extends,
		
	}, metaMetatable))
	
	return meta, extends and extends._init
end

return Classe
