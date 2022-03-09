Scorpio "SpaUI.Widget.Layout.Demo" ""

import "SpaUI.Widget.Layout"
import "SpaUI.Widget"

TestLinearLayout = LinearLayout("TestLinearLayout")
TestLinearLayout:SetLayoutParams(LayoutParams(500, 800))
TestLinearLayout.Gravity = Gravity.CENTER_HORIZONTAL + Gravity.CENTER_VERTICAL
TestLinearLayout:SetPoint("CENTER")

TestButton = UIPanelButton("TestButton")
TestButton:SetText("测试")
local layoutParams = {
    width = SizeMode.WRAP_CONTENT,
    height = SizeMode.WRAP_CONTENT,
    prefWidth = 100,
    prefHeight = 50,
    weight = 0.5
}
TestLinearLayout:AddChild(TestButton, layoutParams)
print("Add Button1")

TestButton2 = UIPanelButton("TestButton2")
TestButton2:SetText("测试2")
local layoutParams2 = {
    width = SizeMode.WRAP_CONTENT,
    height = SizeMode.WRAP_CONTENT,
    prefWidth = 150,
    prefHeight = 200,
    weight = 1
}
TestLinearLayout:AddChild(TestButton2, layoutParams2)
print("Add Button2")

Delay(5, function()
    TestLinearLayout.Orientation = Orientation.HORIZONTAL
end)

Delay(10, function()
    TestLinearLayout.LayoutDirection = LayoutDirection.RIGHT_TO_LEFT
end)