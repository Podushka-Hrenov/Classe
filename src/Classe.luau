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
	parent: index<getmetatable<M>, 'e'>,
	
	phantomMeta: getmetatable<M>,
	meta: {
		__index: index<getmetatable<M>, 'm'>,
	},
	
	new: Types.moveParams<Types.find<
		index<getmetatable<M>, 'm'>, 'construct'>, 
	'2', nil, '1', () -> Types.sortTable<Self<M>, '^_'>>,
	
	initChain: {(self: Types.table, ...any) -> ()},
	
	_construct: Types.find<index<
		getmetatable<M>, 'm'>, 'construct'>,
}


local Classe, __meta = {}, {}

function __meta:__newindex(key: any, value: any)
	self.meta.__index[key] = value
	
	local childs = self.childs
	
	for i = 1, #childs do
		local child = childs[i]
		
		if child.overrides[key] then continue end
		child.meta.__index[key] = value
	end
end

table.freeze(__meta)

Classe.build = function<M>(meta: M): Classe<M>
	assert(type(meta)=='table', 'Meta must be a table')
	
	local construct = meta.construct
	assert(construct, "Construct function not found!")
	
	local self = {
		childs = {},
		overrides = {},
		meta = meta,
	}
	
	local parent = getmetatable(meta).e
	setmetatable(meta, nil)
	
	self.parent = parent
	
	local initChain = nil; if parent then
		table.insert(parent.childs, self)

		for k, v in parent.meta.__index do
			if not meta[k] then continue end 
			self.overrides[k] = true
		end
		
		if meta.init then
			initChain = table.clone(parent.initChain)
			table.insert(initChain, meta.init)
		else
			initChain = parent.initChain
		end
		
	else initChain = {meta.init} end
	
	self.initChain = table.freeze(initChain)
	
	meta.__index = {}
	meta.construct, meta.init = nil, nil;
	self._construct = construct
	
	for index, data in meta do
		if type(index) == 'string' and 
			index:find('^__') then
			
			continue
		end
		
		meta[index] = nil
		meta.__index[index] = data
	end
	
	local initChainLen = #initChain
	
	function self.new(...: any)
		local obj = {}; construct(obj, ...)
		setmetatable(obj, meta)
		
		for i = 1, initChainLen do
			initChain[i](obj)
		end
		
		return obj
	end
	
	setmetatable(self, __meta)
	return table.freeze(self)
end

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
	
	setmetatable(meta, table.freeze{
		e = extends,	
	})
	
	return meta, extends and extends._construct
end

return table.freeze(Classe)
