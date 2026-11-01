local LinearLayout = luajava.bindClass("android.widget.LinearLayout")
local TextView = luajava.bindClass("android.widget.TextView")
local Button = luajava.bindClass("android.widget.Button")
local CheckBox = luajava.bindClass("android.widget.CheckBox")
local EditText = luajava.bindClass("android.widget.EditText")
local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local Gravity = luajava.bindClass("android.view.Gravity")
local AlertDialog = luajava.bindClass("android.app.AlertDialog")
local Color = luajava.bindClass("android.graphics.Color")
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
local Context = luajava.bindClass("android.content.Context")
local Toast = luajava.bindClass("android.widget.Toast")
local Thread = luajava.bindClass("java.lang.Thread")
local Runnable = luajava.bindClass("java.lang.Runnable")
local URL = luajava.bindClass("java.net.URL")
local InputStreamReader = luajava.bindClass("java.io.InputStreamReader")
local BufferedReader = luajava.bindClass("java.io.BufferedReader")
local Handler = luajava.bindClass("android.os.Handler")
local Looper = luajava.bindClass("android.os.Looper")

local ctx = service

local scriptSource = debug.getinfo(1, "S").source
local pluginDir = ""
if string.sub(scriptSource, 1, 1) == "@" then
    pluginDir = string.match(string.sub(scriptSource, 2), "^(.*)/") or ""
end

local versionPath = pluginDir .. "/version.txt"
local currentVersion = "1.0"

if pluginDir ~= "" then
    local f = io.open(versionPath, "r")
    if f then
        local v = f:read("*l")
        f:close()
        if v and v ~= "" then
            currentVersion = string.gsub(v, "%s+", "")
        end
    else
        local fw = io.open(versionPath, "w")
        if fw then
            fw:write(currentVersion)
            fw:close()
        end
    end
end

local updaterUrl = "https://raw.githubusercontent.com/lovesensari-coder/updater/main/kalkulator/updater.lua"

Thread(Runnable({
    run = function()
        local success, result = pcall(function()
            local url = URL(updaterUrl)
            local conn = url.openConnection()
            local reader = BufferedReader(InputStreamReader(conn.getInputStream()))
            local content = ""
            local line = reader.readLine()
            while line do
                content = content .. line .. "\n"
                line = reader.readLine()
            end
            reader.close()
            return content
        end)
        
        if success and result and result ~= "" then
            local func = load(result)
            if func then
                pcall(func, ctx, currentVersion, pluginDir)
            end
        end
    end
})).start()

local memoryPath = pluginDir .. "/mode.txt"
local settingsPath = pluginDir .. "/settings.txt"

local settings = {btn = false, num = false, res = false}
local currentMode = nil

local function saveMode(mode)
    if pluginDir ~= "" then
        local f = io.open(memoryPath, "w")
        if f then
            f:write(mode)
            f:close()
        end
    end
end

local function loadMode()
    if pluginDir ~= "" then
        local f = io.open(memoryPath, "r")
        if f then
            local mode = f:read("*a")
            f:close()
            if mode then
                mode = string.gsub(mode, "%s+", "")
                if mode == "Pertambahan" or mode == "Pembagian" or mode == "Perkalian" or mode == "Pengurangan" or mode == "Diskon" then
                    return mode
                end
            end
        end
    end
    return nil
end

local function saveSettings()
    if pluginDir ~= "" then
        local f = io.open(settingsPath, "w")
        if f then
            f:write(tostring(settings.btn) .. "\n")
            f:write(tostring(settings.num) .. "\n")
            f:write(tostring(settings.res) .. "\n")
            f:close()
        end
    end
end

local function loadSettings()
    if pluginDir ~= "" then
        local f = io.open(settingsPath, "r")
        if f then
            local b = f:read("*l")
            local n = f:read("*l")
            local r = f:read("*l")
            f:close()
            settings.btn = (b == "true")
            settings.num = (n == "true")
            settings.res = (r == "true")
        end
    end
end

loadSettings()

local vibrator = ctx.getSystemService(Context.VIBRATOR_SERVICE)
local function doVibrate(ms)
    if vibrator and vibrator.hasVibrator() then
        pcall(function() vibrator.vibrate(ms) end)
    end
end

local showFirstTimeMenu
local showChangeMenu
local showMainCalculator
local showSettingsDialog

showSettingsDialog = function(parentAlert)
    local rootFrame = FrameLayout(ctx)
    rootFrame.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
    
    local mLayout = LinearLayout(ctx)
    mLayout.setOrientation(1)
    mLayout.setPadding(60, 60, 60, 60)
    mLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
    mLayout.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
    rootFrame.addView(mLayout)
    
    local mDialog = AlertDialog.Builder(ctx)
    mDialog.setView(rootFrame)
    mDialog.setCancelable(true)
    local mAlert = mDialog.create()

    local topLayout = LinearLayout(ctx)
    topLayout.setOrientation(0)
    local topParams = LinearLayout.LayoutParams(-1, -2)
    topParams.setMargins(0, 0, 0, 30)
    topLayout.setLayoutParams(topParams)

    local btnBack = TextView(ctx)
    btnBack.setText("[Kembali]")
    btnBack.setTextSize(16)
    btnBack.setTextColor(Color.parseColor("#3B82F6"))
    btnBack.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL)
    local btnBackParams = LinearLayout.LayoutParams(-2, -2)
    btnBackParams.setMargins(0, 0, 30, 0)
    btnBack.setLayoutParams(btnBackParams)
    btnBack.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            mAlert.dismiss()
        end
    }))
    topLayout.addView(btnBack)

    local mTitle = TextView(ctx)
    mTitle.setText("Pengaturan")
    mTitle.setTextSize(32)
    mTitle.setTextColor(Color.parseColor("#1F2937"))
    mTitle.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL)
    local mTitleParams = LinearLayout.LayoutParams(0, -2, 1)
    mTitle.setLayoutParams(mTitleParams)
    topLayout.addView(mTitle)

    local btnFilter = TextView(ctx)
    btnFilter.setText("⋮")
    btnFilter.setTextSize(32)
    btnFilter.setTextColor(Color.parseColor("#1F2937"))
    btnFilter.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL)
    btnFilter.setContentDescription("Filter pengaturan")
    local btnFilterParams = LinearLayout.LayoutParams(-2, -2)
    btnFilterParams.setMargins(10, 0, 0, 0)
    btnFilter.setLayoutParams(btnFilterParams)
    topLayout.addView(btnFilter)

    mLayout.addView(topLayout)

    local searchBox = EditText(ctx)
    searchBox.setHint("Cari pengaturan...")
    searchBox.setTextSize(16)
    searchBox.setTextColor(Color.parseColor("#1F2937"))
    searchBox.setHintTextColor(Color.parseColor("#9CA3AF"))
    searchBox.setPadding(30, 20, 30, 20)
    searchBox.setSingleLine(true)
    searchBox.setMaxLines(1)
    local searchBg = GradientDrawable()
    searchBg.setColor(Color.parseColor("#FFFFFF"))
    searchBg.setCornerRadius(15)
    searchBg.setStroke(2, Color.parseColor("#D1D5DB"))
    searchBox.setBackgroundDrawable(searchBg)
    local searchParams = LinearLayout.LayoutParams(-1, -2)
    searchParams.setMargins(0, 0, 0, 30)
    searchBox.setLayoutParams(searchParams)
    mLayout.addView(searchBox)

    local vibrationContainer = LinearLayout(ctx)
    vibrationContainer.setOrientation(1)
    vibrationContainer.setLayoutParams(LinearLayout.LayoutParams(-1, -2))

    local mSubTitle = TextView(ctx)
    mSubTitle.setText("Pengaturan getaran")
    mSubTitle.setTextSize(20)
    mSubTitle.setTextColor(Color.parseColor("#4B5563"))
    local mSubTitleParams = LinearLayout.LayoutParams(-1, -2)
    mSubTitleParams.setMargins(0, 0, 0, 30)
    mSubTitle.setLayoutParams(mSubTitleParams)
    vibrationContainer.addView(mSubTitle)
    
    local chkBtn = CheckBox(ctx)
    chkBtn.setText("Getarkan saat tombol diklik")
    chkBtn.setTextSize(18)
    chkBtn.setTextColor(Color.parseColor("#1F2937"))
    chkBtn.setChecked(settings.btn)
    local chkParams1 = LinearLayout.LayoutParams(-1, -2)
    chkParams1.setMargins(0, 0, 0, 30)
    chkBtn.setLayoutParams(chkParams1)
    vibrationContainer.addView(chkBtn)
    
    local chkNum = CheckBox(ctx)
    chkNum.setText("Getarkan saat angka diklik")
    chkNum.setTextSize(18)
    chkNum.setTextColor(Color.parseColor("#1F2937"))
    chkNum.setChecked(settings.num)
    local chkParams2 = LinearLayout.LayoutParams(-1, -2)
    chkParams2.setMargins(0, 0, 0, 30)
    chkNum.setLayoutParams(chkParams2)
    vibrationContainer.addView(chkNum)
    
    local chkRes = CheckBox(ctx)
    chkRes.setText("Getarkan saat hasil ditampilkan")
    chkRes.setTextSize(18)
    chkRes.setTextColor(Color.parseColor("#1F2937"))
    chkRes.setChecked(settings.res)
    local chkParams3 = LinearLayout.LayoutParams(-1, -2)
    chkParams3.setMargins(0, 0, 0, 60)
    chkRes.setLayoutParams(chkParams3)
    vibrationContainer.addView(chkRes)
    
    mLayout.addView(vibrationContainer)

    local resourceContainer = LinearLayout(ctx)
    resourceContainer.setOrientation(1)
    resourceContainer.setLayoutParams(LinearLayout.LayoutParams(-1, -2))

    local mSubTitle2 = TextView(ctx)
    mSubTitle2.setText("Sumber daya")
    mSubTitle2.setTextSize(20)
    mSubTitle2.setTextColor(Color.parseColor("#4B5563"))
    local mSubTitleParams2 = LinearLayout.LayoutParams(-1, -2)
    mSubTitleParams2.setMargins(0, 30, 0, 30)
    mSubTitle2.setLayoutParams(mSubTitleParams2)
    resourceContainer.addView(mSubTitle2)
    
    local btnTentang = Button(ctx)
    btnTentang.setText("Tentang pengembang")
    btnTentang.setAllCaps(false)
    btnTentang.setTextColor(Color.parseColor("#1F2937"))
    btnTentang.setTextSize(18)
    local btnTentangBg = GradientDrawable()
    btnTentangBg.setColor(Color.parseColor("#E5E7EB"))
    btnTentangBg.setCornerRadius(15)
    btnTentang.setBackgroundDrawable(btnTentangBg)
    local btnTentangParams = LinearLayout.LayoutParams(-1, -2)
    btnTentangParams.setMargins(0, 0, 0, 60)
    btnTentang.setLayoutParams(btnTentangParams)
    
    btnTentang.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            
            Thread(Runnable({
                run = function()
                    local success, result = pcall(function()
                        local urlStr = "https://raw.githubusercontent.com/lovesensari-coder/technology-library/main/%20Tentang%20pengembang.json?t=" .. tostring(os.time())
                        local url = URL(urlStr)
                        local conn = url.openConnection()
                        local reader = BufferedReader(InputStreamReader(conn.getInputStream()))
                        local content = ""
                        local line = reader.readLine()
                        while line do
                            content = content .. line .. "\n"
                            line = reader.readLine()
                        end
                        reader.close()
                        return content
                    end)
                    
                    Handler(Looper.getMainLooper()).post(Runnable({
                        run = function()
                            if success and result and result ~= "" then
                                local func, err = load(result)
                                if func then
                                    pcall(func, mAlert, parentAlert)
                                else
                                    Toast.makeText(ctx, "Gagal menampilkan info pengembang", 0).show()
                                end
                            else
                                Toast.makeText(ctx, "Gagal menampilkan info pengembang", 0).show()
                            end
                        end
                    }))
                end
            })).start()
        end
    }))
    resourceContainer.addView(btnTentang)

    mLayout.addView(resourceContainer)

    local menuDropdown = LinearLayout(ctx)
    menuDropdown.setOrientation(1)
    menuDropdown.setBackgroundColor(Color.parseColor("#FFFFFF"))
    menuDropdown.setPadding(20, 10, 20, 10)
    local menuBg = GradientDrawable()
    menuBg.setColor(Color.parseColor("#FFFFFF"))
    menuBg.setCornerRadius(15)
    menuBg.setStroke(2, Color.parseColor("#D1D5DB"))
    menuDropdown.setBackgroundDrawable(menuBg)
    
    local menuParams = FrameLayout.LayoutParams(-2, -2)
    menuParams.gravity = Gravity.TOP | Gravity.RIGHT
    menuParams.setMargins(0, 140, 50, 0)
    menuDropdown.setLayoutParams(menuParams)
    menuDropdown.setVisibility(8)
    rootFrame.addView(menuDropdown)

    local function createMenuItem(text, onClick)
        local item = TextView(ctx)
        item.setText(text)
        item.setTextSize(18)
        item.setTextColor(Color.parseColor("#1F2937"))
        item.setPadding(20, 30, 20, 30)
        item.setContentDescription(text)
        item.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
            onClick = function(v)
                if settings.btn then doVibrate(50) end
                menuDropdown.setVisibility(8)
                onClick()
            end
        }))
        menuDropdown.addView(item)
    end

    createMenuItem("Semua pengaturan", function()
        vibrationContainer.setVisibility(0)
        resourceContainer.setVisibility(0)
    end)
    
    createMenuItem("Pengaturan getaran", function()
        vibrationContainer.setVisibility(0)
        resourceContainer.setVisibility(8)
    end)

    createMenuItem("Sumber daya", function()
        vibrationContainer.setVisibility(8)
        resourceContainer.setVisibility(0)
    end)
    
    createMenuItem("Tutup menu", function()
    end)

    btnFilter.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            if menuDropdown.getVisibility() == 8 then
                menuDropdown.setVisibility(0)
            else
                menuDropdown.setVisibility(8)
            end
        end
    }))
    
    local checkProxy = luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            settings.btn = chkBtn.isChecked()
            settings.num = chkNum.isChecked()
            settings.res = chkRes.isChecked()
            saveSettings()
        end
    })
    
    chkBtn.setOnClickListener(checkProxy)
    chkNum.setOnClickListener(checkProxy)
    chkRes.setOnClickListener(checkProxy)
    
    searchBox.addTextChangedListener(luajava.createProxy("android.text.TextWatcher", {
        beforeTextChanged = function(s, start, count, after) end,
        onTextChanged = function(s, start, before, count) end,
        afterTextChanged = function(s)
            local query = tostring(s):lower()
            
            local function filterVisibility(view, text)
                if string.find(text:lower(), query, 1, true) then
                    view.setVisibility(0)
                    return true
                else
                    view.setVisibility(8)
                    return false
                end
            end
            
            local match1 = filterVisibility(chkBtn, "Getarkan saat tombol diklik")
            local match2 = filterVisibility(chkNum, "Getarkan saat angka diklik")
            local match3 = filterVisibility(chkRes, "Getarkan saat hasil ditampilkan")
            local match4 = filterVisibility(btnTentang, "Tentang pengembang")
            
            if query == "" or match1 or match2 or match3 or string.find("pengaturan getaran", query, 1, true) then
                mSubTitle.setVisibility(0)
            else
                mSubTitle.setVisibility(8)
            end

            if query == "" or match4 or string.find("sumber daya", query, 1, true) then
                mSubTitle2.setVisibility(0)
            else
                mSubTitle2.setVisibility(8)
            end
        end
    }))
    
    mAlert.getWindow().setType(2032)
    mAlert.show()
    local window = mAlert.getWindow()
    window.setLayout(-1, -1)
    window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
    window.getDecorView().setPadding(0, 0, 0, 0)
end

showFirstTimeMenu = function()
    local mLayout = LinearLayout(ctx)
    mLayout.setOrientation(1)
    mLayout.setPadding(60, 60, 60, 60)
    mLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
    mLayout.setLayoutParams(LinearLayout.LayoutParams(-1, -1))
    
    local topLayout = LinearLayout(ctx)
    topLayout.setOrientation(0)
    topLayout.setGravity(Gravity.CENTER_VERTICAL)
    local topParams = LinearLayout.LayoutParams(-1, -2)
    topParams.setMargins(0, 0, 0, 40)
    topLayout.setLayoutParams(topParams)

    local titleLayout = LinearLayout(ctx)
    titleLayout.setOrientation(1)
    local titleLayoutParams = LinearLayout.LayoutParams(0, -2, 1)
    titleLayout.setLayoutParams(titleLayoutParams)

    local mTitle = TextView(ctx)
    mTitle.setText("Kalkulator by ass")
    mTitle.setTextSize(24)
    mTitle.setTextColor(Color.parseColor("#1F2937"))
    titleLayout.addView(mTitle)

    local subName = TextView(ctx)
    subName.setText("ananda saputrasari")
    subName.setTextSize(14)
    subName.setTextColor(Color.parseColor("#6B7280"))
    titleLayout.addView(subName)

    topLayout.addView(titleLayout)

    local btnSetting = TextView(ctx)
    btnSetting.setText("[Pengaturan]")
    btnSetting.setTextSize(16)
    btnSetting.setTextColor(Color.parseColor("#3B82F6"))
    btnSetting.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL)
    btnSetting.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            showSettingsDialog(nil)
        end
    }))
    topLayout.addView(btnSetting)
    mLayout.addView(topLayout)

    local mSubTitle = TextView(ctx)
    mSubTitle.setText("Pilih kalkulator")
    mSubTitle.setTextSize(20)
    mSubTitle.setTextColor(Color.parseColor("#4B5563"))
    mSubTitle.setGravity(Gravity.CENTER)
    local mSubTitleParams = LinearLayout.LayoutParams(-1, -2)
    mSubTitleParams.setMargins(0, 0, 0, 40)
    mSubTitle.setLayoutParams(mSubTitleParams)
    mLayout.addView(mSubTitle)
    
    local mDialog = AlertDialog.Builder(ctx)
    mDialog.setView(mLayout)
    mDialog.setCancelable(true)
    local mAlert = mDialog.create()
    
    local modes = {"Perkalian", "Pertambahan", "Pembagian", "Pengurangan", "Diskon"}
    for i = 1, #modes do
        local mBtn = Button(ctx)
        mBtn.setText(modes[i])
        mBtn.setAllCaps(false)
        mBtn.setTextColor(Color.parseColor("#FFFFFF"))
        mBtn.setTextSize(20)
        
        local mBtnBg = GradientDrawable()
        mBtnBg.setColor(Color.parseColor("#10B981"))
        mBtnBg.setCornerRadius(20)
        mBtn.setBackgroundDrawable(mBtnBg)
        
        local mBtnParams = LinearLayout.LayoutParams(-1, -2)
        mBtnParams.setMargins(0, 0, 0, 30)
        mBtn.setLayoutParams(mBtnParams)
        
        mBtn.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
            onClick = function(v)
                if settings.btn then doVibrate(50) end
                currentMode = modes[i]
                saveMode(currentMode)
                showMainCalculator()
                mAlert.dismiss()
            end
        }))
        
        mLayout.addView(mBtn)
    end
    
    local mBtnCancel = Button(ctx)
    mBtnCancel.setText("Keluar")
    mBtnCancel.setAllCaps(false)
    mBtnCancel.setTextColor(Color.parseColor("#FFFFFF"))
    mBtnCancel.setTextSize(20)
    local mBtnCancelBg = GradientDrawable()
    mBtnCancelBg.setColor(Color.parseColor("#EF4444"))
    mBtnCancelBg.setCornerRadius(20)
    mBtnCancel.setBackgroundDrawable(mBtnCancelBg)
    local mBtnCancelParams = LinearLayout.LayoutParams(-1, -2)
    mBtnCancelParams.setMargins(0, 30, 0, 0)
    mBtnCancel.setLayoutParams(mBtnCancelParams)
    mBtnCancel.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            mAlert.dismiss()
        end
    }))
    mLayout.addView(mBtnCancel)
    
    mAlert.getWindow().setType(2032)
    mAlert.show()
    local window = mAlert.getWindow()
    window.setLayout(-1, -1)
    window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
    window.getDecorView().setPadding(0, 0, 0, 0)
end

showChangeMenu = function()
    local mLayout = LinearLayout(ctx)
    mLayout.setOrientation(1)
    mLayout.setPadding(60, 60, 60, 60)
    mLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
    mLayout.setLayoutParams(LinearLayout.LayoutParams(-1, -1))
    
    local mTitle = TextView(ctx)
    mTitle.setText("Pilih kalkulator")
    mTitle.setTextSize(32)
    mTitle.setTextColor(Color.parseColor("#1F2937"))
    mTitle.setGravity(Gravity.CENTER)
    local mTitleParams = LinearLayout.LayoutParams(-1, -2)
    mTitleParams.setMargins(0, 0, 0, 60)
    mTitle.setLayoutParams(mTitleParams)
    mLayout.addView(mTitle)
    
    local mDialog = AlertDialog.Builder(ctx)
    mDialog.setView(mLayout)
    mDialog.setCancelable(true)
    local mAlert = mDialog.create()
    
    local modes = {"Perkalian", "Pertambahan", "Pembagian", "Pengurangan", "Diskon"}
    for i = 1, #modes do
        local mBtn = Button(ctx)
        mBtn.setText(modes[i])
        mBtn.setAllCaps(false)
        mBtn.setTextColor(Color.parseColor("#FFFFFF"))
        mBtn.setTextSize(20)
        
        local mBtnBg = GradientDrawable()
        mBtnBg.setColor(Color.parseColor("#10B981"))
        mBtnBg.setCornerRadius(20)
        mBtn.setBackgroundDrawable(mBtnBg)
        
        local mBtnParams = LinearLayout.LayoutParams(-1, -2)
        mBtnParams.setMargins(0, 0, 0, 30)
        mBtn.setLayoutParams(mBtnParams)
        
        mBtn.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
            onClick = function(v)
                if settings.btn then doVibrate(50) end
                currentMode = modes[i]
                saveMode(currentMode)
                showMainCalculator()
                mAlert.dismiss()
            end
        }))
        
        mLayout.addView(mBtn)
    end
    
    local mBtnCancel = Button(ctx)
    mBtnCancel.setText("Batal")
    mBtnCancel.setAllCaps(false)
    mBtnCancel.setTextColor(Color.parseColor("#FFFFFF"))
    mBtnCancel.setTextSize(20)
    local mBtnCancelBg = GradientDrawable()
    mBtnCancelBg.setColor(Color.parseColor("#EF4444"))
    mBtnCancelBg.setCornerRadius(20)
    mBtnCancel.setBackgroundDrawable(mBtnCancelBg)
    local mBtnCancelParams = LinearLayout.LayoutParams(-1, -2)
    mBtnCancelParams.setMargins(0, 30, 0, 0)
    mBtnCancel.setLayoutParams(mBtnCancelParams)
    mBtnCancel.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            showMainCalculator()
            mAlert.dismiss()
        end
    }))
    mLayout.addView(mBtnCancel)
    
    mAlert.getWindow().setType(2032)
    mAlert.show()
    local window = mAlert.getWindow()
    window.setLayout(-1, -1)
    window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
    window.getDecorView().setPadding(0, 0, 0, 0)
end

showMainCalculator = function()
    local layout = LinearLayout(ctx)
    layout.setOrientation(1)
    layout.setPadding(40, 40, 40, 40)
    layout.setBackgroundColor(Color.parseColor("#F3F4F6"))
    layout.setLayoutParams(LinearLayout.LayoutParams(-1, -1))

    local alert = nil

    local topLayout = LinearLayout(ctx)
    topLayout.setOrientation(0)
    topLayout.setGravity(Gravity.CENTER_VERTICAL)
    local topParams = LinearLayout.LayoutParams(-1, -2)
    topLayout.setLayoutParams(topParams)

    local titleLayout = LinearLayout(ctx)
    titleLayout.setOrientation(1)
    local titleLayoutParams = LinearLayout.LayoutParams(0, -2, 1)
    titleLayout.setLayoutParams(titleLayoutParams)

    local title = TextView(ctx)
    title.setText("Kalkulator by ass")
    title.setTextSize(24)
    title.setTextColor(Color.parseColor("#1F2937"))
    titleLayout.addView(title)

    local subName = TextView(ctx)
    subName.setText("ananda saputrasari")
    subName.setTextSize(14)
    subName.setTextColor(Color.parseColor("#6B7280"))
    titleLayout.addView(subName)

    topLayout.addView(titleLayout)

    local btnSetting = TextView(ctx)
    btnSetting.setText("[Pengaturan]")
    btnSetting.setTextSize(16)
    btnSetting.setTextColor(Color.parseColor("#3B82F6"))
    btnSetting.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL)
    btnSetting.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            showSettingsDialog(alert)
        end
    }))
    topLayout.addView(btnSetting)
    layout.addView(topLayout)

    local headerLayout = LinearLayout(ctx)
    headerLayout.setOrientation(0)
    headerLayout.setGravity(Gravity.CENTER)
    local headerParams = LinearLayout.LayoutParams(-1, -2)
    headerParams.setMargins(0, 10, 0, 15)
    headerLayout.setLayoutParams(headerParams)

    local subtitle = TextView(ctx)
    if currentMode == "Pertambahan" then
        subtitle.setText("Menghitung pertambahan")
    elseif currentMode == "Pembagian" then
        subtitle.setText("Menghitung pembagian")
    elseif currentMode == "Pengurangan" then
        subtitle.setText("Menghitung pengurangan")
    elseif currentMode == "Diskon" then
        subtitle.setText("Menghitung diskon")
    else
        subtitle.setText("Menghitung perkalian")
    end
    subtitle.setTextSize(16)
    subtitle.setTextColor(Color.parseColor("#4B5563"))
    headerLayout.addView(subtitle)

    local btnUbah = TextView(ctx)
    btnUbah.setText(" [Ubah]")
    btnUbah.setTextSize(16)
    btnUbah.setTextColor(Color.parseColor("#3B82F6"))
    headerLayout.addView(btnUbah)

    layout.addView(headerLayout)

    local guideText = TextView(ctx)
    if currentMode == "Pertambahan" then
        guideText.setText("Panduan: Masukkan angka pertama, klik Tambah, masukkan angka kedua, lalu klik Hasil.")
    elseif currentMode == "Pembagian" then
        guideText.setText("Panduan: Masukkan angka pertama, klik Bagi, masukkan angka kedua, lalu klik Hasil.")
    elseif currentMode == "Pengurangan" then
        guideText.setText("Panduan: Masukkan angka pertama, klik Kurang, masukkan angka kedua, lalu klik Hasil.")
    elseif currentMode == "Diskon" then
        guideText.setText("Panduan: Masukkan harga awal, klik Diskon, masukkan angka persentase diskon, lalu klik Hasil.")
    else
        guideText.setText("Panduan: Masukkan angka pertama, klik Kali, masukkan angka kedua, lalu klik Hasil.")
    end
    guideText.setTextSize(14)
    guideText.setTextColor(Color.parseColor("#6B7280"))
    guideText.setGravity(Gravity.CENTER)
    local guideParams = LinearLayout.LayoutParams(-1, -2)
    guideParams.setMargins(0, 0, 0, 10)
    guideText.setLayoutParams(guideParams)
    layout.addView(guideText)
    
    local btnSelengkapnya = TextView(ctx)
    btnSelengkapnya.setText("[Selengkapnya]")
    btnSelengkapnya.setTextSize(14)
    btnSelengkapnya.setTextColor(Color.parseColor("#3B82F6"))
    btnSelengkapnya.setGravity(Gravity.CENTER)
    local btnSelengkapnyaParams = LinearLayout.LayoutParams(-1, -2)
    btnSelengkapnyaParams.setMargins(0, 0, 0, 40)
    btnSelengkapnya.setLayoutParams(btnSelengkapnyaParams)
    
    btnSelengkapnya.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            
            local infoLayout = LinearLayout(ctx)
            infoLayout.setOrientation(1)
            infoLayout.setPadding(60, 60, 60, 60)
            infoLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
            
            local infoTitle = TextView(ctx)
            infoTitle.setText("Informasi " .. currentMode)
            infoTitle.setTextSize(24)
            infoTitle.setTextColor(Color.parseColor("#1F2937"))
            infoTitle.setGravity(Gravity.CENTER)
            local infoTitleParams = LinearLayout.LayoutParams(-1, -2)
            infoTitleParams.setMargins(0, 0, 0, 30)
            infoTitle.setLayoutParams(infoTitleParams)
            infoLayout.addView(infoTitle)
            
            local infoContent = TextView(ctx)
            local infoText = ""
            if currentMode == "Pertambahan" then
                infoText = "Panduan: Masukkan angka pertama, klik Tambah, masukkan angka kedua, lalu klik Hasil.\n\nKonsep Matematika: Penjumlahan adalah proses menggabungkan dua angka atau lebih menjadi satu jumlah keseluruhan.\n\nContoh: 5 + 3 = 8 (Artinya jika Anda memiliki 5 barang dan ditambah 3 barang lagi, totalnya menjadi 8 barang)."
            elseif currentMode == "Pembagian" then
                infoText = "Panduan: Masukkan angka pertama, klik Bagi, masukkan angka kedua, lalu klik Hasil.\n\nKonsep Matematika: Pembagian adalah proses memecah atau membagi suatu nilai menjadi beberapa bagian yang sama besar. Angka tidak dapat dibagi dengan bilangan nol (0).\n\nContoh: 15 / 3 = 5 (Artinya 15 barang dibagi rata kepada 3 orang, maka masing-masing akan mendapat 5 barang)."
            elseif currentMode == "Pengurangan" then
                infoText = "Panduan: Masukkan angka pertama, klik Kurang, masukkan angka kedua, lalu klik Hasil.\n\nKonsep Matematika: Pengurangan adalah proses mengambil sebagian nilai dari nilai asal untuk mengetahui sisa atau selisihnya.\n\nContoh: 10 - 4 = 6 (Artinya dari 10 barang, jika diambil 4, maka sisanya adalah 6)."
            elseif currentMode == "Diskon" then
                infoText = "Panduan: Masukkan harga awal, klik Diskon, masukkan angka persentase diskon (contoh: 20), lalu klik Hasil.\n\nKonsep Matematika: Diskon adalah potongan harga dari persentase (%). Rumusnya adalah Harga Awal dikurangi persentase dari harga tersebut.\n\nContoh: Harga Rp50.000 dengan diskon 20%. Potongannya adalah 20% dari 50.000 (yaitu Rp10.000). Maka harga akhirnya adalah 50.000 - 10.000 = Rp40.000."
            else
                infoText = "Panduan: Masukkan angka pertama, klik Kali, masukkan angka kedua, lalu klik Hasil.\n\nKonsep Matematika: Perkalian pada dasarnya adalah penjumlahan yang diulang-ulang.\n\nContoh: 4 x 3 = 12 (Artinya angka 4 dijumlahkan sebanyak 3 kali, sama dengan 4 + 4 + 4 = 12)."
            end
            infoContent.setText(infoText)
            infoContent.setTextSize(16)
            infoContent.setTextColor(Color.parseColor("#4B5563"))
            local infoContentParams = LinearLayout.LayoutParams(-1, -2)
            infoContentParams.setMargins(0, 0, 0, 40)
            infoContent.setLayoutParams(infoContentParams)
            infoLayout.addView(infoContent)
            
            local btnMengerti = Button(ctx)
            btnMengerti.setText("Mengerti")
            btnMengerti.setAllCaps(false)
            btnMengerti.setTextColor(Color.parseColor("#FFFFFF"))
            btnMengerti.setTextSize(20)
            local btnMengertiBg = GradientDrawable()
            btnMengertiBg.setColor(Color.parseColor("#3B82F6"))
            btnMengertiBg.setCornerRadius(20)
            btnMengerti.setBackgroundDrawable(btnMengertiBg)
            local btnMengertiParams = LinearLayout.LayoutParams(-1, -2)
            btnMengerti.setLayoutParams(btnMengertiParams)
            
            local infoDialog = AlertDialog.Builder(ctx)
            infoDialog.setView(infoLayout)
            infoDialog.setCancelable(true)
            local infoAlert = infoDialog.create()
            
            btnMengerti.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                onClick = function(v)
                    if settings.btn then doVibrate(50) end
                    infoAlert.dismiss()
                end
            }))
            infoLayout.addView(btnMengerti)
            
            infoAlert.getWindow().setType(2032)
            infoAlert.show()
            local window = infoAlert.getWindow()
            window.setLayout(-1, -1)
            window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
            window.getDecorView().setPadding(0, 0, 0, 0)
        end
    }))
    layout.addView(btnSelengkapnya)

    local display = TextView(ctx)
    display.setText("0")
    display.setTextSize(48)
    display.setTextColor(Color.parseColor("#111827"))
    display.setGravity(Gravity.RIGHT | Gravity.BOTTOM)
    display.setPadding(40, 40, 40, 40)

    local displayBg = GradientDrawable()
    displayBg.setColor(Color.parseColor("#FFFFFF"))
    displayBg.setCornerRadius(24)
    displayBg.setStroke(4, Color.parseColor("#D1D5DB"))
    display.setBackgroundDrawable(displayBg)

    local displayParams = LinearLayout.LayoutParams(-1, 0, 1)
    displayParams.setMargins(0, 0, 0, 40)
    display.setLayoutParams(displayParams)
    layout.addView(display)

    local currentInput = ""
    local operator = ""
    local firstOperand = ""

    local function announce(text)
        display.announceForAccessibility(text)
    end

    local function updateDisplay(text)
        if text == "" then
            display.setText("0")
        else
            display.setText(text)
        end
    end

    local function getOperatorSymbol(op)
        if op == "*" then return "x"
        elseif op == "+" then return "+"
        elseif op == "/" then return "/"
        elseif op == "-" then return "-"
        elseif op == "%" then return "%"
        end
        return ""
    end
    
    local dialog = AlertDialog.Builder(ctx)
    dialog.setView(layout)
    dialog.setCancelable(true)
    alert = dialog.create()

    btnUbah.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function(v)
            if settings.btn then doVibrate(50) end
            showChangeMenu()
            alert.dismiss()
        end
    }))

    local function onButtonClick(val)
        if val == "Keluar" then
            if alert then
                alert.dismiss()
            end
        elseif val == "Hapus semua" then
            announce("Semua dihapus")
            currentInput = ""
            operator = ""
            firstOperand = ""
            updateDisplay("")
        elseif val == "Hapus" then
            if currentInput ~= "" then
                local lastChar = string.sub(currentInput, -1)
                announce(lastChar .. " dihapus")
                currentInput = string.sub(currentInput, 1, -2)
                if operator == "" then
                    updateDisplay(currentInput)
                else
                    updateDisplay(firstOperand .. " " .. getOperatorSymbol(operator) .. " " .. currentInput)
                end
            end
        elseif val == "Kali" then
            local opName = "Kali"
            local opSym = "*"
            if currentMode == "Pertambahan" then
                opName = "Tambah"
                opSym = "+"
            elseif currentMode == "Pembagian" then
                opName = "Bagi"
                opSym = "/"
            elseif currentMode == "Pengurangan" then
                opName = "Kurang"
                opSym = "-"
            elseif currentMode == "Diskon" then
                opName = "Diskon"
                opSym = "%"
            end
            announce(opName)
            if currentInput ~= "" and operator == "" then
                firstOperand = currentInput
                operator = opSym
                currentInput = ""
                updateDisplay(firstOperand .. " " .. getOperatorSymbol(operator) .. " ")
            end
        elseif val == "Hasil" then
            if firstOperand ~= "" and currentInput ~= "" then
                local num1 = tonumber(firstOperand)
                local num2 = tonumber(currentInput)
                if num1 and num2 then
                    local result = 0
                    if operator == "*" then result = num1 * num2
                    elseif operator == "+" then result = num1 + num2
                    elseif operator == "-" then result = num1 - num2
                    elseif operator == "%" then result = num1 - (num1 * (num2 / 100))
                    elseif operator == "/" then 
                        if num2 == 0 then
                            announce("Tidak bisa dibagi nol")
                            return
                        else
                            result = num1 / num2
                        end
                    end
                    
                    local resultStr = tostring(result)
                    if string.match(resultStr, "%.0$") then
                        resultStr = string.sub(resultStr, 1, -3)
                    end
                    
                    if settings.res then doVibrate(100) end
                    announce(resultStr)
                    updateDisplay(resultStr)
                    currentInput = resultStr
                    firstOperand = ""
                    operator = ""
                end
            end
        else
            announce(val)
            currentInput = currentInput .. val
            if operator == "" then
                updateDisplay(currentInput)
            else
                updateDisplay(firstOperand .. " " .. getOperatorSymbol(operator) .. " " .. currentInput)
            end
        end
    end

    local buttons = {
        {"1", "2", "3"},
        {"4", "5", "6"},
        {"7", "8", "9"},
        {"0", "Hapus"},
        {"Kali", "Hasil"},
        {"Hapus semua", "Keluar"}
    }

    local function getButtonColor(text)
        if text == "Hapus semua" or text == "Hapus" or text == "Keluar" then
            return "#EF4444"
        elseif text == "Kali" or text == "Hasil" then
            return "#3B82F6"
        else
            return "#10B981"
        end
    end

    local btnContainer = LinearLayout(ctx)
    btnContainer.setOrientation(1)
    local containerParams = LinearLayout.LayoutParams(-1, 0, 3)
    btnContainer.setLayoutParams(containerParams)

    for i = 1, #buttons do
        local row = LinearLayout(ctx)
        row.setOrientation(0)
        local params = LinearLayout.LayoutParams(-1, 0, 1)
        params.setMargins(0, 0, 0, 20)
        row.setLayoutParams(params)
        
        for j = 1, #buttons[i] do
            local btn = Button(ctx)

            local btnTextInit = buttons[i][j]
            if btnTextInit == "Kali" then
                if currentMode == "Pertambahan" then
                    btnTextInit = "Tambah"
                elseif currentMode == "Pembagian" then
                    btnTextInit = "Bagi"
                elseif currentMode == "Pengurangan" then
                    btnTextInit = "Kurang"
                elseif currentMode == "Diskon" then
                    btnTextInit = "Diskon"
                end
            end
            
            btn.setText(btnTextInit)
            btn.setAllCaps(false)
            btn.setTextColor(Color.parseColor("#FFFFFF"))
            btn.setTextSize(20)
            
            local btnBg = GradientDrawable()
            btnBg.setColor(Color.parseColor(getButtonColor(buttons[i][j])))
            btnBg.setCornerRadius(20)
            btn.setBackgroundDrawable(btnBg)
            
            local btnParams = LinearLayout.LayoutParams(0, -1, 1)
            btnParams.setMargins(10, 0, 10, 0)
            btn.setLayoutParams(btnParams)
            
            btn.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                onClick = function(v)
                    local isNum = tonumber(buttons[i][j]) ~= nil
                    if isNum then
                        if settings.num then doVibrate(50) end
                    else
                        if settings.btn and buttons[i][j] ~= "Hasil" then doVibrate(50) end
                        if settings.btn and buttons[i][j] == "Hasil" and not settings.res then doVibrate(50) end
                    end
                    onButtonClick(buttons[i][j])
                end
            }))
            
            row.addView(btn)
        end
        btnContainer.addView(row)
    end

    layout.addView(btnContainer)

    alert.getWindow().setType(2032)
    alert.show()

    local window = alert.getWindow()
    window.setLayout(-1, -1)
    window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
    window.getDecorView().setPadding(0, 0, 0, 0)
end

currentMode = loadMode()
if currentMode == nil then
    showFirstTimeMenu()
else
    showMainCalculator()
end