-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code to support MVA implementations

local TSM = select(2, ...)

function TSMAPI:CreateMVA(addon, name)
	local mvcObj = addon:NewModule(name)
	mvcObj.RegisterModel = function(self, ...)
		assert(not self.Model)
		self.Model = self:NewModule(self.name.."_Model", ...)
		return self.Model
	end
	mvcObj.RegisterAdapter = function(self, ...)
		assert(not self.Adapter)
		self.Adapter = self:NewModule(self.name.."_Adapter", ...)
		return self.Adapter
	end
	mvcObj.RegisterView = function(self, ...)
		assert(not self.View)
		self.View = self:NewModule(self.name.."_View", ...)
		return self.View
	end
	mvcObj.RegisterViewHelper = function(self, ...)
		assert(not self.ViewHelper)
		self.ViewHelper = self:NewModule(self.name.."_ViewHelper", ...)
		return self.ViewHelper
	end
	return mvcObj
end