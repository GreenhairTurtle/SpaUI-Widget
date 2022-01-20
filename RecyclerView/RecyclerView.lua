-----------------------------------------------------------
--         Warcraft version of Android recyclerView      --
-----------------------------------------------------------
Scorpio "SpaUI.Widget.RecyclerView" ""

namespace "SpaUI.Widget.Recycler"

class "ItemDecoration" {}

class "ItemView" { Frame }

class "RecyclerView" { ScrollFrame }

-----------------------------------------------------------
--                     ScrollBar                         --
-----------------------------------------------------------

-- 滑块表示当前显示的列表项的数目的滚动条，每次滚动只移动1，对应列表1个item
__Sealed__()
class "ScrollBar"(function()
    inherit "Frame"

    local function ScrollToCursorValue(self)
        local uiScale, cursorX, cursorY = self:GetEffectiveScale(),  GetCursorPosition()
        local left, top = self:GetLeft(), self:GetTop()
        cursorX, cursorY = cursorX/uiScale, cursorY/uiScale
        
        local offset, length = 0, 0

        if self.Orientation == Orientation.HORIZONTAL then
            offset = cursorX - left
            length = self:GetWidth()
        elseif self.Orientation == Orientation.VERTICAL then
            offset = top - cursorY
            length = self:GetHeight()
        end

        if offset > length then
            offset = length
        elseif offset < 0 then
            offset = 0
        end

        local value = math.floor(offset / length * self.Range + 0.5)
        if value < 1 then
            value = 1
        end

        self:SetValue(value, true)
    end

    local function Thumb_OnUpdate(self, elapsed)
        self.timeSinceLast = self.timeSinceLast + elapsed
        if self.timeSinceLast >= 0.08 then
            self.timeSinceLast = 0
            ScrollToCursorValue(self:GetParent())
        end
    end

    local function Thumb_OnMouseUp(self, button)
        self.OnUpdate = self.OnUpdate - Thumb_OnUpdate
    end

    local function Thumb_OnMouseDown(self, button)
        if button == "LeftButton" then
            self.timeSinceLast = 0
            self.OnUpdate = self.OnUpdate + Thumb_OnUpdate
        end
    end

    local function GetThumbRange(self)
        local recyclerView = self:GetParent()
        if recyclerView then
            return recyclerView:GetVisibleItemViewCount()
        end

        return 1
    end

    local function OnMouseWheel(self, delta)
        local value = self:GetValue() - delta
        if value < 1 then
            value = 1
        elseif value > self.Range then
            value = self.Range
        end
        self:SetValue(value, true)
    end

    
    local function OnMouseDown(self, button)
        ScrollToCursorValue(self)
    end

    -- Hold down
    local function ScrollButton_Update(self, elapsed)
        self.timeSinceLast = self.timeSinceLast + elapsed
        if self.timeSinceLast >= 0.08 then
            if not IsMouseButtonDown("LeftButton") then
                self:SetScript("OnUpdate", nil)
            elseif self:IsMouseOver() then
                OnMouseWheel(self:GetParent(), self.direction)
                self.timeSinceLast = 0
            end
        end
    end

    local function ScrollButton_OnClick(self, button, down)
        if down and button == "LeftButton" then
            self.timeSinceLast = -0.2
            self:SetScript("OnUpdate", ScrollButton_Update)
            OnMouseWheel(self:GetParent(), self.direction)
            PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
        else
            self:SetScript("OnUpdate", nil)
        end
    end

    local function Show(self)
        self:SetAlpha(1)
        local current = GetTime()
        self.ShowTime = current
        self.FadeoutTarget = current + self.FadeoutDelay + self.FadeoutDuration
    end

    local function OnLeave(self)
        -- do nothing
    end

    local function OnEnter(self)
        Show(self)
    end

    local function IsMouseOver(self)
        if self:IsMouseOver() then return true end

        for _, child in self:GetChilds() do
            if child:IsMouseOver() then return true end
        end
    end

    local function OnUpdate(self, elapsed)
        if IsMouseOver(self) then
            Show(self)
        else
            local current = GetTime()
            if self.FadeoutTarget and current <= self.FadeoutTarget and current - (self.ShowTime or 0) > self.FadeoutDelay then
                local alpha = (self.FadeoutTarget - current)/self.FadeoutDuration
                self:SetAlpha(alpha)
            end
        end
    end

    local function ScrollButton_OnEnter(self)
        OnEnter(self:GetParent())
    end

    local function ScrollButton_OnLeave(self)
        OnLeave(self:GetParent())
    end

    local function RefreshScrollButtonStates(self)
        local value = self:GetValue()
        local scrollUpButton = self:GetChild("ScrollUpButton")
        local scrollDownButton = self:GetChild("ScrollDownButton")
        local recyclerView = self:GetParent()
        if value <= 1 then
            scrollUpButton:Disable()
        else
            scrollUpButton:Enable()
        end
        if value >= self.Range or (recyclerView and recyclerView:IsScrollToBottom()) then
            scrollDownButton:Disable()
        else
            scrollDownButton:Enable()
        end
    end

    local function OnValueChanged(self, value, userInput)
        Show(self)
        if userInput then
            local recyclerView = self:GetParent()
            if recyclerView then
                recyclerView:ScrollToPosition(self:GetValue())
            end
        end
    end

    local function UpdateThumb(self)
        local thumb = self:GetChild("Thumb")
        local thumbRange = GetThumbRange(self)
        local length = self:GetLength()
        local thumbLength = (thumbRange or 1) / self.Range * length
        local value = self:GetValue()
        local offset = (value - 1) / self.Range * length
        local point = "TOPLEFT"
        
        if offset + thumbLength > length then
            offset = 0
            point = "BOTTOMRIGHT"
        end
 
        thumb:ClearAllPoints()
        if self.Orientation == Orientation.HORIZONTAL then
            thumb:SetWidth(thumbLength)
            thumb:SetHeight(self:GetHeight())
            thumb:SetPoint(point, offset, 0)
        elseif self.Orientation == Orientation.VERTICAL then
            thumb:SetHeight(thumbLength)
            thumb:SetWidth(self:GetWidth())
            thumb:SetPoint(point, 0, -offset)
        end
    end

    local function OnRangeChanged(self)
        self:SetValue(self:GetValue())
    end

    __Final__()
    function GetLength(self)
        if self.Orientation == Orientation.HORIZONTAL then
            return self:GetWidth()
        elseif self.Orientation == Orientation.VERTICAL then
            return self:GetHeight()
        end
    end
    
    __Final__()
    __Arguments__{ NaturalNumber, Boolean/false }
    function SetValue(self, value, userInput)
        local max = self.Range

        if value > max then
            value = max
        end

        local oldValue = self.Value
        self.Value = value
        UpdateThumb(self)
        RefreshScrollButtonStates(self)

        if value ~= oldValue then
            OnValueChanged(self, value, userInput)
        end
    end

    __Final__()
    function GetValue(self)
        return self.Value or 1
    end

    __Final__()
    __Arguments__{ NaturalNumber }
    function SetRange(self, range)
        self.Range = range
    end

    -- 渐隐
    property "Fadeout"          {
        type                    = Boolean,
        handler                 = function(self, fadeout)
            if fadeout then
                self.OnUpdate = self.OnUpdate + OnUpdate
            else
                self.OnUpdate = self.OnUpdate - OnUpdate
            end
        end
    }

    -- 渐隐时间
    property "FadeoutDuration"  {
        type                    = Number,
        default                 = 4
    }

    -- 渐隐延迟
    property "FadeoutDelay"     {
        type                    = Number,
        default                 = 2
    }

    -- 范围
    property "Range"            {
        type                    = NaturalNumber,
        default                 = 1,
        handler                 = OnRangeChanged
    }

    -- 方向
    property "Orientation"      {
        type                    = Orientation,
        default                 = Orientation.VERTICAL
    }

    __Template__{
        ScrollUpButton          = Button,
        ScrollDownButton        = Button,
        Thumb                   = Button
    }
    __InstantApplyStyle__()
    function __ctor(self)
        self:SetAlpha(0)

        local scrollUpButton        = self:GetChild("ScrollUpButton")
        local scrollDownButton      = self:GetChild("ScrollDownButton")
        local thumb                 = self:GetChild("Thumb")
        
        scrollUpButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
        scrollUpButton.direction    = 1
        scrollDownButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
        scrollDownButton.direction  = -1

        scrollUpButton.OnClick      = scrollUpButton.OnClick + ScrollButton_OnClick
        scrollUpButton.OnEnter      = scrollUpButton.OnEnter + ScrollButton_OnEnter
        scrollUpButton.OnLeave      = scrollUpButton.OnLeave + ScrollButton_OnLeave

        scrollDownButton.OnClick    = scrollDownButton.OnClick + ScrollButton_OnClick
        scrollDownButton.OnEnter    = scrollDownButton.OnEnter + ScrollButton_OnEnter
        scrollDownButton.OnLeave    = scrollDownButton.OnLeave + ScrollButton_OnLeave

        thumb.OnMouseDown           = thumb.OnMouseDown + Thumb_OnMouseDown
        thumb.OnMouseUp             = thumb.OnMouseUp + Thumb_OnMouseUp

        self.OnMouseWheel           = self.OnMouseWheel + OnMouseWheel
        self.OnEnter                = self.OnEnter + OnEnter
        self.OnLeave                = self.OnLeave + OnLeave
        self.OnMouseDown            = self.OnMouseDown + OnMouseDown
    end

end)

__Sealed__()
class "HorizontalScrollBar" { ScrollBar }

__Sealed__()
class "VerticalScrollBar"   { ScrollBar }

-----------------------------------------------------------
--                  ViewHolder                           --
-----------------------------------------------------------

__Sealed__()
class "ViewHolder"(function()

    property "Position"             {
        type                        = NaturalNumber
    }

    property "Orientation"          {
        type                        = Orientation
    }

    function Destroy(self)
        self.Orientation = nil
        self.Position = nil
        self.ContentView:Hide()
        self.ContentView:ClearAllPoints()
        self.ContentView:SetParent(nil)
    end

    __Arguments__{ LayoutFrame, Integer }
    function __ctor(self, contentView, itemViewType)
        self.ContentView = contentView
        self.ItemViewType = itemViewType
    end

end)

-----------------------------------------------------------
--          Decoration and item view                     --
--Each recyclerView can contain multiple item decoration --
-----------------------------------------------------------

__Sealed__()
class "ItemView"(function()

    property "ViewHolder"           {
        type                        = ViewHolder,
        handler                     = function(self, viewHolder)
            if viewHolder then
                viewHolder.Orientation = self.Orientation
            end
        end
    }

    property "DecorationViews"      {
        type                        = RawTable,
        default                     = function() return {} end,
        set                         = false
    }

    property "Orientation"          {
        type                        = Orientation,
        handler                     = function(self, orientation)
            if self.ViewHolder then
                self.ViewHolder.Orientation = orientation
            end
        end
    }

    function GetContentLength(self)
        local length = 0
        if self.ViewHolder then
            if self.Orientation == Orientation.VERTICAL then
                length = self.ViewHolder.ContentView:GetHeight()
            elseif self.Orientation == Orientation.HORIZONTAL then
                length = self.ViewHolder.ContentView:GetWidth()
            end
        end
        return length
    end

    function GetLength(self)
        if self.Orientation == Orientation.VERTICAL then
            return self:GetHeight()
        elseif self.Orientation == Orientation.HORIZONTAL then
            return self:GetWidth()
        end
    end

    function Destroy(self)
        self:Hide()
        self:ClearAllPoints()
        self:SetParent(nil)
    end

end)

__Sealed__()
class "ItemDecoration"(function()

    -- 返回每项item的间距
    -- left, right, top, bottom
    __Abstract__()
    function GetItemMargins(RecyclerView, ViewHolder)
        return 0, 0, 0, 0
    end

    -- 返回DecorationView
    __Abstract__()
    function OnCreateDecorationView(self)
    end

    -- 返回Overlay View
    function OnCreateOverlayView(self)
    end

    __Arguments__{ RecyclerView, LayoutFrame, ViewHolder }
    __Abstract__()
    function Draw(self, recyclerView, decorationView, viewHolder)
    end

    __Arguments__{ RecyclerView, LayoutFrame }
    __Abstract__()
    function DrawOver(self, recyclerView, overlayView)
    end

    __Arguments__{ ItemView }
    function RecycleDecorationView(self, itemView)
        local decorationView = itemView.DecorationViews[self]
        if not decorationView then return end

        decorationView:Hide()
        decorationView:ClearAllPoints()
        decorationView:SetParent(nil)
        tinsert(self.__DecorationViewCache, decorationView)

        itemView.DecorationViews[self] = nil
    end

    __Arguments__{ RecyclerView, ItemView }
    function AttachItemView(self, recyclerView, itemView)
        local decorationView = itemView.DecorationViews[self]
        
        if not decorationView then
            decorationView = tremove(self.__DecorationViewCache)

            if not decorationView then
                decorationView = self:OnCreateDecorationView()
            end
        end

        itemView.DecorationViews[self] = decorationView

        if decorationView then
            decorationView:SetParent(itemView)
            decorationView:SetAllPoints(itemView)
            self:Draw(recyclerView, decorationView, itemView.ViewHolder)
            decorationView:Show()
        end
    end

    __Arguments__{ RecyclerView }
    function RecycleOverlayView(self, recyclerView)
        local overlayView = recyclerView.OverlayViews[self]
        if overlayView then
            overlayView:Hide()
            overlayView:ClearAllPoints()
            overlayView:SetParent(nil)
        end
        tinsert(self.__OverlayViewCache, overlayView)

        recyclerView.OverlayViews[self] = nil
    end

    __Arguments__{ RecyclerView }:Throwable()
    function ShowOverlayView(self, recyclerView)
        local overlayView = recyclerView.OverlayViews[self]
        if not overlayView then
            overlayView = tremove(self.__OverlayViewCache)

            if not overlayView then
                overlayView = self:OnCreateOverlayView()
                if overlayView and not Class.ValidateValue(Frame, overlayView) then
                    throw("OverlayView必须是Frame或其子类型")
                end
            end

            recyclerView.OverlayViews[self] = overlayView
        end

        if overlayView then
            overlayView:SetParent(recyclerView)
            overlayView:SetFrameStrata(recyclerView:GetFrameStrata())
            overlayView:SetToplevel(true)
            self:DrawOver(recyclerView, overlayView)
            overlayView:Show()
        end
    end

    function Destroy(self, recyclerView)
        self:RecycleOverlayView(recyclerView)

        for _, itemView in recyclerView:GetItemViews() do
            self:RecycleDecorationView(itemView)
        end
    end

    function __ctor(self)
        self.__DecorationViewCache = {}
        self.__OverlayViewCache = {}
    end

end)

-----------------------------------------------------------
--                      Adapter                          --
-----------------------------------------------------------

__Sealed__()
class "Adapter"(function()

    property "Data"                 {
        type                        = List,
        handler                     = function(self)
            self:NotifyDataSetChanged(false)
        end
    }

    property "RecyclerView"         {
        type                        = RecyclerView
    }

    -- 空布局
    property "EmptyView"            {
        type                        = LayoutFrame,
        handler                     = function(self, newView, oldView)
            if oldView then
                oldView:SetParent(nil)
                oldView:ClearAllPoints()
                oldView:Hide()
            end

            if newView and self:GetItemCount() <= 0 then
                self:NotifyDataSetChanged()
            end
        end
    }

    -- 刷新
    __Final__()
    __Arguments__{ Boolean/true }
    function NotifyDataSetChanged(self, keepPosition)
        if self.RecyclerView then
            self.RecyclerView:Refresh(keepPosition)
        end
    end
    
    -- 如果需要实现多布局，重写这个方法，需返回整数
    __Arguments__{ NaturalNumber }
    function GetItemViewType(self, position)
        return 0
    end

    -- 获取item数量，必须是自然数
    __Final__()
    function GetItemCount(self)
        return self.Data and self.Data.Count or 0
    end

    __Arguments__{ Integer }
    __Final__()
    function CreateViewHolder(self, viewType)
        return ViewHolder(self:OnCreateContentView(viewType), viewType)
    end

    -- 重写该方法返回ContentView
    -- @param viewType: 由GetItemViewType获取
    __Abstract__()
    __Arguments__{ Integer }
    function OnCreateContentView(self, viewType)
    end

    -- 绑定ViewHolder
    -- @param holder: ViewHolder
    -- @param position: 数据源位置
    __Final__()
    __Arguments__{ ViewHolder, NaturalNumber }
    function BindViewHolder(self, holder, position)
        self:OnBindViewHolder(holder, position)
        holder.Position = position
    end

    -- 重写该方法实现数据绑定
    __Arguments__{ ViewHolder, NaturalNumber }
    __Abstract__()
    function OnBindViewHolder(self, holder, position)
    end

    -- 回收ItemView的ViewHolder
    __Arguments__{ ItemView }
    function RecycleViewHolder(self, itemView)
        local viewHolder = itemView.ViewHolder
        if not viewHolder then return end

        viewHolder:Destroy()
        
        local viewHolderCache = self.__ViewHolderCache[viewHolder.ItemViewType]
        if not viewHolderCache then
            viewHolderCache = {}
            self.__ViewHolderCache[viewHolder.ItemViewType] = viewHolderCache
        end

        tinsert(viewHolderCache, viewHolder)

        itemView.ViewHolder = nil
    end

    -- 判断是否需要刷新
    -- @param itemView: ItemView
    -- @param position: 数据源位置
    __Arguments__{ ItemView, NaturalNumber }
    function NeedRefresh(self, itemView, position)
        local itemViewType = self:GetItemViewType(position)
        return not itemView.ViewHolder or itemView.ViewHolder.Position ~= position or itemView.ViewHolder.ItemViewType ~= itemViewType
    end

    -- 获取回收池内ViewHolder数量
    function GetViewHolderCount(self)
        local count = 0
        for _, cache in pairs(self.__ViewHolderCache) do
            count = count + #cache
        end

        return count
    end

    local function GetViewHolderFromCache(self, itemViewType)
        if self.__ViewHolderCache[itemViewType] then
            return tremove(self.__ViewHolderCache[itemViewType])
        end
    end

    -- Adapter附着到ItemView，这个方法实现数据绑定
    -- @param itemView: ItemView
    -- @param position: 数据源位置
    __Arguments__{ ItemView, NaturalNumber }
    function AttachItemView(self, itemView, position)
        local itemViewType = self:GetItemViewType(position)

        if itemView.ViewHolder and itemView.ViewHolder.ItemViewType ~= itemViewType then
            self:RecycleViewHolder(itemView)
        end

        local viewHolder = itemView.ViewHolder

        if not viewHolder then
            viewHolder = GetViewHolderFromCache(self, itemViewType)
            if not viewHolder then
                viewHolder = self:CreateViewHolder(itemViewType)
            end
            itemView.ViewHolder = viewHolder
        end

        viewHolder.ContentView:SetParent(itemView)
        self:BindViewHolder(viewHolder, position)
        viewHolder.ContentView:Show()
    end

    function __ctor(self)
        self.__ViewHolderCache = {}
    end
    
end)

-----------------------------------------------------------
--                  LayoutManager                        --
-----------------------------------------------------------

__Sealed__()
class "LayoutManager"(function()

    property "RecylerView"          {
        type                        = RecyclerView,
        handler                     = function(self)
            self.LayoutPosition = nil
            self.LayoutOffset = nil
        end
    }

    property "LayoutPosition"       {
        type                        = NaturalNumber,
        default                     = 1
    }

    property "LayoutOffset"         {
        type                        = Number,
        default                     = 0
    }

    -- 从指定位置和偏移量开始布局，是布局的入口
    -- @param: position: item位置,第一个完整显示在RecyclerView可视范围内的item位置
    -- @param: offset: 该position对应的itemView当前滚动位置
    -- @parm: forceRefresh:强制刷新。正常情况下，已经显示的Item在刷新的时候会被忽略，这个参数可以控制这个特性是否运作
    __Final__()
    __Arguments__{ NaturalNumber, Number, Boolean/false }
    function Layout(self, position, offset, forceRefresh)
        if self.RecyclerView and self.RecyclerView.Adapter then
            local itemCount = self.RecyclerView.Adapter:GetItemCount()
            position = math.min(position, itemCount)
            if position <= 0 then return end
            
            self.LayoutPosition = position
            -- position大于item数量，则跳转到最后一项，offset设为0
            self.LayoutOffset = position > itemCount and 0 or offset

            if forceRefresh then
                self.RecyclerView:RecycleItemViews()
                return self:Layout(self.LayoutPosition, self.LayoutOffset)
            end

            self:OnLayout(self.LayoutPosition, self.LayoutOffset)
        end
    end

    -- @see Layout
    -- LayoutManager的子类应当重写这个方法来实现自己的布局
    __Abstract__()
    __Arguments__{ NaturalNumber, Number }
    function OnLayout(self, position, offset)
    end

    __Abstract__()
    function LayoutItemViews(self)
    end

    -- 获取可见的ItemView数量
    __Abstract__()
    function GetVisibleItemViewCount(self)
    end

    -- @return
    -- @param itemView 返回第一个完整可见的item
    -- @param index itemView index
    -- @param offset 该item位置
    __Abstract__()
    function GetFirstCompletelyVisibleItemView(self)
    end

    -- 请求重新布局
    -- @param keepPosition: 保留当前位置，即刷新后仍停留在当前item
    __Arguments__{ Boolean/false }
    function RequestLayout(self, keepPosition)
        self:Layout(keepPosition and self.LayoutPosition or 1, 0, true)
    end

    -- 滚动到指定位置
    -- @param position:数据源位置
    function ScrollToPosition(self, position)
        if position ~= self.LayoutPosition or self.LayoutOffset ~= 0 then
            self:Layout(position, 0)
        end
    end

end)

-----------------------------------------------------------
--                    RecyclerView                       --
-----------------------------------------------------------

__Sealed__()
class "RecyclerView"(function()

    struct "ItemViewInfo"   {
        { name = "Position", type = NaturalNumber,  require = true },
        { name = "ItemView", type = ItemView,       require = true }
    }

    -------------------------------------------------------
    --                      Pool                         --
    -------------------------------------------------------

    local itemViewPool              = Recycle(ItemView, "RecyclerView.ItemView%d")

    function itemViewPool:OnPush(itemView)
        itemView:Destroy()
    end

    local function AcquireItemView(self)
        local itemView = itemViewPool()
        local scrollChild = self:GetChild("ScrollChild")
        itemView:SetParent(scrollChild)
        itemView:SetFrameStrata(scrollChild:GetFrameStrata())
        itemView:SetFrameLevel(scrollChild:GetFrameLevel())
        itemView.Orientation = self.Orientation
        return itemView
    end

    local function ReleaseItemView(self, itemView)
        itemViewPool(itemView)
    end

    -------------------------------------------------------
    --                    Property                       --
    -------------------------------------------------------

    property "Orientation"          {
        type                        = Orientation,
        default                     = Orientation.VERTICAL,
        handler                     = "OnOrientationChanged"
    }

    property "LayoutManager"        {
        type                        = LayoutManager,
        handler                     = "OnLayoutManagerChanged"
    }

    property "Adapter"              {
        type                        = Adapter,
        handler                     = "OnAdapterChanged"
    }

    __Indexer__(Any)
    property "OverlayViews"         {
        type                        = LayoutFrame,
        set                         = function(self, key, value)
            self.__OverlayViews = self.__OverlayViews or {}
            self.__OverlayViews[key] = value
        end,
        get                         = function(self, key)
            return self.__OverlayViews and self.__OverlayViews[key]
        end
    }

    -------------------------------------------------------
    --                    Functions                      --
    -------------------------------------------------------

    -- 刷新空布局
    function RefreshEmptyView(self)
        if self.Adapter then
            local emptyView = self.Adapter.EmptyView
            if not emptyView then return end

            local itemCount = self.Adapter:GetItemCount()
            if itemCount <= 0 then
                emptyView:ClearAllPoints()
                emptyView:SetParent(self)
                emptyView:SetAllPoints(self)
                emptyView:Show()
            else
                emptyView:Hide()
            end
        end
    end

    -- 绘制ItemDecorations
    __Arguments__{ ItemView }
    function DrawItemDecorations(self, itemView)
        for _, itemDecoration in pairs(self.__ItemDecorations) do
            itemDecoration:AttachItemView(self, itemView)
        end
    end

    -- 绘制ItemDecorations的Overlay
    function DrawItemDecorationsOverlay(self)
        for _, itemDecoration in ipairs(self.__ItemDecorations) do
            itemDecoration:ShowOverlayView(self)
        end
    end

    -- 返回ItemDecorations的迭代器
    function GetItemDecorations(self)
        return ipairs(self.__ItemDecorations)
    end

    -- 添加ItemDecoration
    __Arguments__{ ItemDecoration }
    function AddItemDecoration(self, itemDecoration)
        if not tContains(self.__ItemDecorations, itemDecoration) then
            tinsert(self.__ItemDecorations, itemDecoration)
        end
    end

    -- 删除ItemDecoration
    __Arguments__{ ItemDecoration }
    function RemoveItemDecoration(self, itemDecoration)
        itemDecoration:Destroy(self)
        tDeleteItem(self.__ItemDecorations, itemDecoration)
        self:Refresh(true)
    end

    -- LayoutManager变更
    function OnLayoutManagerChanged(self, layoutManager, oldLayoutManager)
        if oldLayoutManager then
            oldLayoutManager.RecyclerView = nil
        end

        if layoutManager then
            layoutManager.RecyclerView = self
        end

        self:Refresh()
    end

    -- 方向变更
    function OnOrientationChanged(self)
        for _, itemView in ipairs(self.__ItemViews) do
            itemView.Orientation = self.Orientation
        end
        self:ResetScroll()
        self:Refresh(true)
    end

    -- 适配器变更
    function OnAdapterChanged(self, newAdapter, oldAdapter)
        if oldAdapter then
            oldAdapter.RecyclerView = nil
        end

        if newAdapter then
            newAdapter.RecyclerView = self
        end

        self:Refresh(oldAdapter)
    end

    -- 刷新
    __Arguments__{ Adapter/nil }
    function Refresh(self, adapter)
        self:Refresh(false, adapter)
    end


    -- 刷新
    -- @param keepPosition: 保留当前位置，即刷新后仍停留在当前item
    -- @param adapter 指定ViewHolder回收到哪个adapter，默认为nil，即当前adapter
    __Arguments__{ Boolean/false, Adapter/nil }
    function Refresh(self, keepPosition, adapter)
        self:RefreshScrollBar()
        self:RecycleItemViews(adapter)
        if self.LayoutManager then
            self.LayoutManager:RequestLayout(keepPosition)
        end
        self:RefreshEmptyView()
        self:DrawItemDecorationsOverlay()
    end

    -- 刷新ScrollBar
    function RefreshScrollBar(self)
        -- 先隐藏，由LayoutManager决定是否显示
        -- @see SetScrollBarVisible
        self:HideScrollBars()

        local scrollBar = self:GetScrollBar()
        local adapter = self.Adapter
        if adapter then
            local count = adapter:GetItemCount()
            if count > 0 then
                scrollBar:SetRange(count)
                scrollBar:SetValue(1)
            end
        end
    end

    -- 跳转到指定item
    -- @param position: item位置
    __Arguments__{ NaturalNumber }
    function ScrollToPosition(self, position)
        if self.LayoutManager then
            self.LayoutManager:ScrollToPosition(position)
        end
    end

    -- 获取Scrollbar
    function GetScrollBar(self)
        if self.Orientation == Orientation.HORIZONTAL then
            return self:GetChild("HorizontalScrollBar")
        elseif self.Orientation == Orientation.VERTICAL then
            return self:GetChild("VerticalScrollBar")
        end
    end

    -- 设置当前ScrollBar是否显示
    __Arguments__{ Boolean/false }
    function SetScrollBarVisible(self, show)
        self:GetScrollBar():SetShown(show)
    end

    -- 隐藏所有ScrollBar
    function HideScrollBars(self)
        self:GetChild("VerticalScrollBar"):Hide()
        self:GetChild("HorizontalScrollBar"):Hide()
    end

    -- 获取RecyclerView长度，根据其方向会返回长度或宽度
    function GetLength(self)
        if self.Orientation == Orientation.HORIZONTAL then
            return self:GetWidth()
        elseif self.Orientation == Orientation.VERTICAL then
            return self:GetHeight()
        end
    end

    -- 从指定index开始回收ItemViews
    -- @param index: 从指定位置的ItemView往后开始回收
    -- @param adapter: 指定ViewHolder回收到哪个adapter，默认为nil，即当前adapter
    __Arguments__{ Adapter/nil, NaturalNumber/1 }
    function RecycleItemViews(self, adapter, index)
        for i = #self.__ItemViews, index, -1 do
            self:RecycleItemView(i, adapter)
        end
    end
    
    -- 回收指定位置的ItemView
    -- @param index: 指定位置的ItemView
    -- @param adapter: 指定ViewHolder回收到哪个adapter，默认为nil，即当前adapter
    __Arguments__{ NaturalNumber, Adapter/nil }
    function RecycleItemView(self, index, adapter)
        local itemView = tremove(self.__ItemViews, index)
        self:RecycleItemView(itemView, adapter)
    end

    -- 回收ItemView
    -- @param itemView: 需要被回收的itemView
    __Arguments__{ ItemView, Adapter/nil }
    function RecycleItemView(self, itemView, adapter)
        adapter = adapter or self.Adapter
        if adapter then
            adapter:RecycleViewHolder(itemView)
        end

        -- 回收ItemDecoration
        for _, itemDecoration in ipairs(self.__ItemDecorations) do
            itemDecoration:RecycleDecorationView(itemView)
        end

        ReleaseItemView(self, itemView)
    end

    -- 设置ItemViews，由LayoutManager调用
    __Arguments__{ struct {ItemViewInfos} / nil }
    function SetItemViews(self, itemViewInfos)
        if not itemViewInfos then
            self:RecycleItemViews()
            return
        end

        sort(itemViewInfos, function(a, b)
            return a.Position < b.Position
        end)

        local items = {}

        for _, itemViewInfo in ipairs(itemViewInfos) do
            -- 有相同的itemView，说明被复用了，将其移除
            -- 未被移除的会被回收
            for k, v in pairs(self.__ItemViews) do
                if v == itemViewInfo.ItemView then
                    self.__ItemViews[k] = nil
                    break
                end
            end
            tinsert(items, itemViewInfo.ItemView)
        end

        -- 回收没用的ItemView
        for _, itemView in pairs(self.__ItemViews) do
            self:RecycleItemView(itemView, self.Adapter)
        end

        self.__ItemViews = items
    end

    -- 返回ItemViews的迭代器
    function GetItemViews(self)
        return ipairs(self.__ItemViews)
    end

    -- 获取一个新的ItemView，由LayoutManager调用
    -- 由回收池获取或新建返回
    function ObtainItemView(self)
        return AcquireItemView(self)
    end

    -- 获取指定位置的ItemView
    -- @param index:ItemView位置
    __Arguments__{ NaturalNumber }
    function GetItemView(self, index)
        return self.__ItemViews[index]
    end

    -- 获取布局中的ItemView个数
    function GetItemViewCount(self)
        return #self.__ItemViews
    end

    -- 通过adapter position获取ItemView，可能为nil
    -- @param position:数据源内的位置
    function GetItemViewByAdapterPosition(self, position)
        for index, itemView in ipairs(self.__ItemViews) do
            local viewHolder = itemView.ViewHolder
            if viewHolder and viewHolder.Position == position then
                return itemView, index
            end
        end
    end

    -- @itemView 返回第一个完整可见的item
    -- @return
    -- @param itemView: ItemView
    -- @param index:ItemView index
    -- @param offset:ItemView offset
    function GetFirstCompletelyVisibleItemView(self)
        if not self.LayoutManager then return end
    
        return self.LayoutManager:GetFirstCompletelyVisibleItemView()
    end

    -- 获取可见的ItemView数量
    function GetVisibleItemViewCount(self)
        if not self.LayoutManager then
            return 0
        end

        return self.LayoutManager:GetVisibleItemViewCount()
    end

    -- 是否滚动到底部
    function IsScrollToBottom(self)
        local adapter = self.Adapter
        local layoutManager = self.LayoutManager
        local itemViewCount = #self.__ItemViews
        if not adapter or not layoutManager or itemViewCount < 1 then
            return true
        end

        local scrollOffset = math.floor(self:GetScrollOffset())
        local scrollRange = math.floor(self:GetScrollRange())
        local itemCount = adapter:GetItemCount()

        local itemView = self.__ItemViews[#self.__ItemViews]
        if itemView.ViewHolder.Position == itemCount and math.abs(scrollOffset - scrollRange) < 5 then
            return true
        end

        return false
    end

    -- 是否滚动到顶部
    function IsScrollToTop(self)
        local adapter = self.Adapter
        local layoutManager = self.LayoutManager
        local itemViewCount = #self.__ItemViews
        if not adapter or not layoutManager or itemViewCount < 1 then
            return true
        end

        local scrollOffset = math.floor(self:GetScrollOffset())

        local itemView = self.__ItemViews[1]
        if itemView.ViewHolder.Position == 1 and math.abs(scrollOffset) < 5 then
            return true
        end

        return false
    end

    -- 获取滚动范围，根据不同方向返回不同的滚动范围
    function GetScrollRange(self)
        local orientation = self.Orientation
        if orientation == Orientation.VERTICAL then
            return self:GetVerticalScrollRange()
        elseif orientation == Orientation.HORIZONTAL then
            return self:GetHorizontalScrollRange()
        end
    end

    -- 获取滚动值，根据不同方向返回不同的滚动值
    function GetScrollOffset(self)
        local orientation = self.Orientation
        if orientation == Orientation.VERTICAL then
            return self:GetVerticalScroll()
        elseif orientation == Orientation.HORIZONTAL then
            return self:GetHorizontalScroll()
        end
    end

    -- 在当前方向上滚动
    -- @param offset:滚动值
    function Scroll(self, offset)
        local orientation = self.Orientation
        if orientation == Orientation.VERTICAL then
            self:SetVerticalScroll(offset)
        elseif orientation == Orientation.HORIZONTAL then
            self:SetHorizontalScroll(offset)
        end
        -- 刷新ItemDecoration的OverlayView
        self:DrawItemDecorationsOverlay()
    end

    -- 重置滚动值
    function ResetScroll(self)
        self:SetHorizontalScroll(0)
        self:SetVerticalScroll(0)
    end

    -- 鼠标滚轮事件
    -- 这里是滚动驱动入口
    local function OnMouseWheel(self, delta)
        if not self.LayoutManager or not self.Adapter then return end
        
        local scrollRange = self:GetScrollRange()
        if scrollRange <= 0 then return end

        local length = self:GetLength() / 20
        local offset = self:GetScrollOffset() - length * delta

        -- 直接滚动
        self:Scroll(offset)

        -- 判断是否滚动出范围
        -- 滚动出范围，重新刷新
        local itemView, index, curOffset = self:GetFirstCompletelyVisibleItemView()
        if not itemView then return end

        local position = itemView.ViewHolder.Position
        if offset > scrollRange or offset < 0 then
            offset = -(curOffset - offset)
            
            if position == 1 then
                offset = 0
            end

            if itemView then
                self.LayoutManager:Layout(itemView.ViewHolder.Position, offset)
            end
        end

        -- 改变ScrollBar的值
        self:GetScrollBar():SetValue(position)
    end

    -- 大小变化时刷新以触发重绘
    local function OnSizeChanged(self)
        -- 延迟一点时间，以使Scorllbar重新布局，否则Scrollbar.Thumb位置会不正确，因为在重新布局期间调用thumb:SetPoint会使其定位错误
        Delay(0.1, self.Refresh, self, true)
    end

    __Template__{
        VerticalScrollBar           = VerticalScrollBar,
        HorizontalScrollBar         = HorizontalScrollBar,
        ScrollChild                 = Frame
    }
    function __ctor(self)
        self.__ItemViews = {}
        self.__ItemDecorations = {}

        self.OnMouseWheel = self.OnMouseWheel + OnMouseWheel
        self.OnSizeChanged = self.OnSizeChanged + OnSizeChanged

        -- set scroll child
        local scrollChild = self:GetChild("ScrollChild")
        self:SetScrollChild(scrollChild)
        scrollChild:SetPoint("TOPLEFT")
        scrollChild:SetSize(1, 1)
        
        -- set scroll bar
        self:HideScrollBars()
    end

end)


Style.UpdateSkin("Default", {
    [ScrollBar]                                 = {
        fadeout                                 = true
    },

    [VerticalScrollBar]                         = {
        width                                   = 16,

        Thumb                                   = {
            NormalTexture                       = {
                color                           = ColorType(1, 0, 0)
            }
        },

        ScrollUpButton                          = {
            location                            = { Anchor("BOTTOM", 0, 0, nil, "TOP") },
            size                                = Size(18, 16),

            NormalTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
            },
            PushedTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Down]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
            },
            DisabledTexture                     = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Disabled]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
            },
            HighlightTexture                    = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Highlight]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
                alphaMode                       = "ADD",
            }
        },

        ScrollDownButton                        = {
            location                            = { Anchor("TOP", 0, 0, nil, "BOTTOM") },
            size                                = Size(18, 16),

            NormalTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
            },
            PushedTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Down]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
            },
            DisabledTexture                     = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Disabled]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
            },
            HighlightTexture                    = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Highlight]],
                texCoords                       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints                    = true,
                alphaMode                       = "ADD",
            }
        }
    },

    [HorizontalScrollBar]                       = {
        height                                  = 16,
        orientation                             = "HORIZONTAL",

        Thumb                                   = {
            NormalTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-Knob]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.125,
                    LLx                         = 0.2,
                    LLy                         = 0.125,
                    URx                         = 0.8,
                    URy                         = 0.875,
                    LRx                         = 0.2,
                    LRy                         = 0.875
                }
            }
        },
        
        ScrollUpButton                          = {
            location                            = { Anchor("RIGHT", 0, 0, nil, "LEFT") },
            size                                = Size(16, 18),

            NormalTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
            },
            PushedTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Down]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
            },
            DisabledTexture                     = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Disabled]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
            },
            HighlightTexture                    = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Highlight]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
                alphaMode                       = "ADD",
            }
        },

        ScrollDownButton                        = {
            location                            = { Anchor("LEFT", 0, 0, nil, "RIGHT") },
            size                                = Size(16, 18),

            NormalTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
            },
            PushedTexture                       = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Down]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
            },
            DisabledTexture                     = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Disabled]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
            },
            HighlightTexture                    = {
                file                            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Highlight]],
                texCoords                       = {
                    ULx                         = 0.8,
                    ULy                         = 0.25,
                    LLx                         = 0.2,
                    LLy                         = 0.25,
                    URx                         = 0.8,
                    URy                         = 0.75,
                    LRx                         = 0.2,
                    LRy                         = 0.75
                },
                setAllPoints                    = true,
                alphaMode                       = "ADD",
            }
        }
    },

    [RecyclerView]                              = {
        VerticalScrollBar                       = {
            location                            = {
                Anchor("TOPLEFT", 2, -16, nil, "TOPRIGHT"),
                Anchor("BOTTOMLEFT", 2, 16, nil, "BOTTOMRIGHT")
            }
        },

        HorizontalScrollBar                     = {
            location                            = {
                Anchor("TOPLEFT", 16, -2, nil, "BOTTOMLEFT"),
                Anchor("TOPRIGHT", -16, 2, nil, "BOTTOMRIGHT")
            }
        }
    }
})