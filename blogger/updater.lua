local ctx, currentVersion, pluginDir = ...
local jsonUrl = "__JSON_URL__"

local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local LinearLayout = luajava.bindClass("android.widget.LinearLayout")
local ScrollView = luajava.bindClass("android.widget.ScrollView")
local TextView = luajava.bindClass("android.widget.TextView")
local Button = luajava.bindClass("android.widget.Button")
local Gravity = luajava.bindClass("android.view.Gravity")
local AlertDialog = luajava.bindClass("android.app.AlertDialog")
local Color = luajava.bindClass("android.graphics.Color")
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
local Thread = luajava.bindClass("java.lang.Thread")
local Runnable = luajava.bindClass("java.lang.Runnable")
local URL = luajava.bindClass("java.net.URL")
local InputStreamReader = luajava.bindClass("java.io.InputStreamReader")
local BufferedReader = luajava.bindClass("java.io.BufferedReader")
local Handler = luajava.bindClass("android.os.Handler")
local Looper = luajava.bindClass("android.os.Looper")
local FileOutputStream = luajava.bindClass("java.io.FileOutputStream")
local Channels = luajava.bindClass("java.nio.channels.Channels")
local Long = luajava.bindClass("java.lang.Long")

local function fetchText(urlStr)
    local url = URL(urlStr)
    local conn = url.openConnection()
    conn.setConnectTimeout(15000)
    conn.setReadTimeout(15000)
    local reader = BufferedReader(InputStreamReader(conn.getInputStream()))
    local content = ""
    local line = reader.readLine()
    while line do
        content = content .. line .. "\n"
        line = reader.readLine()
    end
    reader.close()
    conn.disconnect()
    return content
end

local function downloadFileStream(urlStr, destPath)
    local url = URL(urlStr)
    local conn = url.openConnection()
    conn.setConnectTimeout(15000)
    conn.setReadTimeout(60000)
    local inStream = conn.getInputStream()
    local outStream = FileOutputStream(destPath)
    local readableChannel = Channels.newChannel(inStream)
    local writableChannel = outStream.getChannel()
    writableChannel.transferFrom(readableChannel, 0, Long.MAX_VALUE)
    writableChannel.close()
    readableChannel.close()
    outStream.flush()
    outStream.close()
    inStream.close()
    conn.disconnect()
    return true
end

local function parseDateVal(dStr)
    if not dStr or dStr == "" then return nil end
    local d, m, y = string.match(dStr, "(%d+)[/%-](%d+)[/%-](%d+)")
    if d and m and y then
        local numD = tonumber(d)
        local numM = tonumber(m)
        local numY = tonumber(y)
        if numD > 1900 then
            return numD * 10000 + numM * 100 + numY
        else
            if numY < 100 then numY = numY + 2000 end
            return numY * 10000 + numM * 100 + numD
        end
    end
    return nil
end

Thread(Runnable({
    run = function()
        local success, result = pcall(fetchText, jsonUrl .. "?t=" .. tostring(os.time()))
        if success and result and result ~= "" then
            local latestVersion = string.match(result, '"latest_version"%s*:%s*"(.-)"')
            local updateDate = string.match(result, '"update_date"%s*:%s*"(.-)"') or os.date("%d/%m/%Y")
            local expiryDate = string.match(result, '"expiry_date"%s*:%s*"(.-)"') or "-"
            local changelog = string.match(result, '"changelog"%s*:%s*"(.-)"') or "-"
            local downloadUrl = string.match(result, '"download_url"%s*:%s*"(.-)"')
            
            if latestVersion and latestVersion ~= currentVersion and downloadUrl then
                changelog = string.gsub(changelog, "\\n", "\n")
                
                local isExpired = false
                local expVal = parseDateVal(expiryDate)
                local todayVal = tonumber(os.date("%Y%m%d"))
                if expVal and todayVal and todayVal >= expVal then
                    isExpired = true
                end
                
                Handler(Looper.getMainLooper()).post(Runnable({
                    run = function()
                        local dm = ctx.getResources().getDisplayMetrics()
                        
                        local function startUpdateDownload()
                            local loadLayout = LinearLayout(ctx)
                            loadLayout.setOrientation(1)
                            loadLayout.setPadding(60, 60, 60, 60)
                            loadLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
                            
                            local loadText = TextView(ctx)
                            loadText.setText("Sedang mengunduh pembaruan...\nMohon tunggu.")
                            loadText.setTextSize(18)
                            loadText.setTextColor(Color.parseColor("#1F2937"))
                            loadText.setGravity(Gravity.CENTER)
                            loadLayout.addView(loadText)
                            
                            local loadDialog = AlertDialog.Builder(ctx)
                            loadDialog.setView(loadLayout)
                            loadDialog.setCancelable(false)
                            local loadAlert = loadDialog.create()
                            loadAlert.getWindow().setType(2032)
                            loadAlert.show()
                            local loadWindow = loadAlert.getWindow()
                            loadWindow.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                            
                            Thread(Runnable({
                                run = function()
                                    local targetFile = string.match(downloadUrl, "/([^/%?]+)%??.*$") or "main.lua"
                                    targetFile = string.gsub(targetFile, "%%20", " ")
                                    local dest = pluginDir .. "/" .. targetFile
                                    Thread.sleep(math.random(1000, 5000))
                                    local dlSuccess = pcall(downloadFileStream, downloadUrl .. "?t=" .. tostring(os.time()), dest)
                                    Handler(Looper.getMainLooper()).post(Runnable({
                                        run = function()
                                            loadAlert.dismiss()
                                            
                                            if dlSuccess then
                                                local fv = io.open(pluginDir .. "/version.txt", "w")
                                                if fv then
                                                    fv:write(latestVersion)
                                                    fv:close()
                                                end
                                                
                                                local succFrame = FrameLayout(ctx)
                                                succFrame.setMinimumHeight(dm.heightPixels)
                                                succFrame.setBackgroundColor(Color.parseColor("#F3F4F6"))
                                                succFrame.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
                                                
                                                local succScroll = ScrollView(ctx)
                                                local ssParams = FrameLayout.LayoutParams(-1, -1)
                                                ssParams.setMargins(0, 0, 0, 220)
                                                succScroll.setLayoutParams(ssParams)
                                                succScroll.setFillViewport(true)
                                                
                                                local succLayout = LinearLayout(ctx)
                                                succLayout.setOrientation(1)
                                                succLayout.setPadding(60, 60, 60, 60)
                                                succLayout.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
                                                
                                                local succTitle = TextView(ctx)
                                                succTitle.setText("Pembaruan Berhasil")
                                                succTitle.setTextSize(24)
                                                succTitle.setTextColor(Color.parseColor("#10B981"))
                                                succTitle.setGravity(Gravity.CENTER)
                                                local succTitleParams = LinearLayout.LayoutParams(-1, -2)
                                                succTitleParams.setMargins(0, 0, 0, 20)
                                                succTitle.setLayoutParams(succTitleParams)
                                                succLayout.addView(succTitle)
                                                
                                                local succMsg = TextView(ctx)
                                                succMsg.setText("Saat ini versi Anda sudah yang terbaru.")
                                                succMsg.setTextSize(16)
                                                succMsg.setTextColor(Color.parseColor("#1F2937"))
                                                succMsg.setGravity(Gravity.CENTER)
                                                local succMsgParams = LinearLayout.LayoutParams(-1, -2)
                                                succMsgParams.setMargins(0, 0, 0, 60)
                                                succMsg.setLayoutParams(succMsgParams)
                                                succLayout.addView(succMsg)
                                                
                                                local infoLayout = LinearLayout(ctx)
                                                infoLayout.setOrientation(0)
                                                local infoParams = LinearLayout.LayoutParams(-1, -2)
                                                infoParams.setMargins(0, 0, 0, 60)
                                                infoLayout.setLayoutParams(infoParams)
                                                
                                                local vInfo = TextView(ctx)
                                                vInfo.setText("Versi saat ini:\n" .. latestVersion)
                                                vInfo.setTextSize(14)
                                                vInfo.setTextColor(Color.parseColor("#6B7280"))
                                                vInfo.setGravity(Gravity.LEFT)
                                                local vInfoParams = LinearLayout.LayoutParams(0, -2, 1)
                                                vInfo.setLayoutParams(vInfoParams)
                                                infoLayout.addView(vInfo)
                                                
                                                local dInfo = TextView(ctx)
                                                dInfo.setText("Tanggal pembaruan:\n" .. updateDate)
                                                dInfo.setTextSize(14)
                                                dInfo.setTextColor(Color.parseColor("#6B7280"))
                                                dInfo.setGravity(Gravity.RIGHT)
                                                local dInfoParams = LinearLayout.LayoutParams(0, -2, 1)
                                                dInfo.setLayoutParams(dInfoParams)
                                                infoLayout.addView(dInfo)
                                                
                                                succLayout.addView(infoLayout)
                                                
                                                local footerMsg = TextView(ctx)
                                                footerMsg.setText("Pembaharuan berhasil terpasang silakan muat ulang untuk menerapkan perubahan")
                                                footerMsg.setTextSize(14)
                                                footerMsg.setTextColor(Color.parseColor("#4B5563"))
                                                footerMsg.setGravity(Gravity.CENTER)
                                                local fMsgParams = LinearLayout.LayoutParams(-1, -2)
                                                fMsgParams.setMargins(0, 0, 0, 40)
                                                footerMsg.setLayoutParams(fMsgParams)
                                                succLayout.addView(footerMsg)
                                                
                                                succScroll.addView(succLayout)
                                                succFrame.addView(succScroll)
                                                
                                                local succBottomBar = LinearLayout(ctx)
                                                succBottomBar.setOrientation(0)
                                                succBottomBar.setGravity(Gravity.CENTER)
                                                succBottomBar.setBackgroundColor(Color.parseColor("#FFFFFF"))
                                                succBottomBar.setPadding(40, 30, 40, 30)
                                                local sbbParams = FrameLayout.LayoutParams(-1, -2)
                                                sbbParams.gravity = Gravity.BOTTOM
                                                succBottomBar.setLayoutParams(sbbParams)
                                                
                                                local btnOk = Button(ctx)
                                                btnOk.setText("Oke")
                                                btnOk.setAllCaps(false)
                                                btnOk.setTextColor(Color.parseColor("#FFFFFF"))
                                                btnOk.setTextSize(18)
                                                local btnOkBg = GradientDrawable()
                                                btnOkBg.setColor(Color.parseColor("#10B981"))
                                                btnOkBg.setCornerRadius(20)
                                                btnOk.setBackgroundDrawable(btnOkBg)
                                                btnOk.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
                                                
                                                local succDialog = AlertDialog.Builder(ctx)
                                                succDialog.setView(succFrame)
                                                succDialog.setCancelable(false)
                                                local succAlert = succDialog.create()
                                                
                                                btnOk.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                                                    onClick = function(v)
                                                        succAlert.dismiss()
                                                        pcall(function() ctx.restart() end)
                                                    end
                                                }))
                                                succBottomBar.addView(btnOk)
                                                succFrame.addView(succBottomBar)
                                                
                                                succAlert.getWindow().setType(2032)
                                                succAlert.show()
                                                local succWindow = succAlert.getWindow()
                                                succWindow.setLayout(-1, -1)
                                                succWindow.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                                                succWindow.getDecorView().setPadding(0, 0, 0, 0)
                                                
                                            else
                                                local failFrame = FrameLayout(ctx)
                                                failFrame.setMinimumHeight(dm.heightPixels)
                                                failFrame.setBackgroundColor(Color.parseColor("#F3F4F6"))
                                                failFrame.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
                                                
                                                local failScroll = ScrollView(ctx)
                                                local fsParams = FrameLayout.LayoutParams(-1, -1)
                                                fsParams.setMargins(0, 0, 0, 220)
                                                failScroll.setLayoutParams(fsParams)
                                                failScroll.setFillViewport(true)
                                                
                                                local failLayout = LinearLayout(ctx)
                                                failLayout.setOrientation(1)
                                                failLayout.setPadding(60, 60, 60, 60)
                                                failLayout.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
                                                
                                                local failTitle = TextView(ctx)
                                                failTitle.setText("Pembaruan gagal")
                                                failTitle.setTextSize(24)
                                                failTitle.setTextColor(Color.parseColor("#EF4444"))
                                                failTitle.setGravity(Gravity.CENTER)
                                                local failTitleParams = LinearLayout.LayoutParams(-1, -2)
                                                failTitleParams.setMargins(0, 0, 0, 20)
                                                failTitle.setLayoutParams(failTitleParams)
                                                failLayout.addView(failTitle)
                                                
                                                local failMsg = TextView(ctx)
                                                failMsg.setText("Mohon maaf, saat ini pembaruan tidak dapat dilakukan. Pastikan koneksi internet Anda stabil dan silakan coba lagi beberapa saat lagi.")
                                                failMsg.setTextSize(16)
                                                failMsg.setTextColor(Color.parseColor("#4B5563"))
                                                failMsg.setGravity(Gravity.CENTER)
                                                local failMsgParams = LinearLayout.LayoutParams(-1, -2)
                                                failMsgParams.setMargins(0, 0, 0, 40)
                                                failMsg.setLayoutParams(failMsgParams)
                                                failLayout.addView(failMsg)
                                                
                                                failScroll.addView(failLayout)
                                                failFrame.addView(failScroll)
                                                
                                                local failBottomBar = LinearLayout(ctx)
                                                failBottomBar.setOrientation(0)
                                                failBottomBar.setGravity(Gravity.CENTER)
                                                failBottomBar.setBackgroundColor(Color.parseColor("#FFFFFF"))
                                                failBottomBar.setPadding(40, 30, 40, 30)
                                                local fbbParams = FrameLayout.LayoutParams(-1, -2)
                                                fbbParams.gravity = Gravity.BOTTOM
                                                failBottomBar.setLayoutParams(fbbParams)
                                                
                                                local btnFailOk = Button(ctx)
                                                btnFailOk.setText("Oke")
                                                btnFailOk.setAllCaps(false)
                                                btnFailOk.setTextColor(Color.parseColor("#FFFFFF"))
                                                btnFailOk.setTextSize(18)
                                                local btnFailBg = GradientDrawable()
                                                btnFailBg.setColor(Color.parseColor("#3B82F6"))
                                                btnFailBg.setCornerRadius(20)
                                                btnFailOk.setBackgroundDrawable(btnFailBg)
                                                btnFailOk.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
                                                
                                                local failDialog = AlertDialog.Builder(ctx)
                                                failDialog.setView(failFrame)
                                                failDialog.setCancelable(false)
                                                local failAlert = failDialog.create()
                                                
                                                btnFailOk.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                                                    onClick = function(v)
                                                        failAlert.dismiss()
                                                    end
                                                }))
                                                failBottomBar.addView(btnFailOk)
                                                failFrame.addView(failBottomBar)
                                                
                                                failAlert.getWindow().setType(2032)
                                                failAlert.show()
                                                local failWindow = failAlert.getWindow()
                                                failWindow.setLayout(-1, -1)
                                                failWindow.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                                                failWindow.getDecorView().setPadding(0, 0, 0, 0)
                                            end
                                        end
                                    }))
                                end
                            })).start()
                        end
                        
                        if isExpired then
                            startUpdateDownload()
                            return
                        end
                        
                        local rootFrame = FrameLayout(ctx)
                        rootFrame.setMinimumHeight(dm.heightPixels)
                        rootFrame.setBackgroundColor(Color.parseColor("#F3F4F6"))
                        rootFrame.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
                        
                        local scroll = ScrollView(ctx)
                        local sParams = FrameLayout.LayoutParams(-1, -1)
                        sParams.setMargins(0, 0, 0, 220)
                        scroll.setLayoutParams(sParams)
                        scroll.setFillViewport(true)
                        
                        local layout = LinearLayout(ctx)
                        layout.setOrientation(1)
                        layout.setPadding(60, 60, 60, 60)
                        layout.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
                        
                        local title = TextView(ctx)
                        title.setText("Update Tersedia")
                        title.setTextSize(24)
                        title.setTextColor(Color.parseColor("#1F2937"))
                        title.setGravity(Gravity.CENTER)
                        local titleParams = LinearLayout.LayoutParams(-1, -2)
                        titleParams.setMargins(0, 0, 0, 20)
                        title.setLayoutParams(titleParams)
                        layout.addView(title)
                        
                        local subtitle = TextView(ctx)
                        subtitle.setText("Perbarui ke versi terbaru untuk pengalaman yang lebih baik")
                        subtitle.setTextSize(14)
                        subtitle.setTextColor(Color.parseColor("#6B7280"))
                        subtitle.setGravity(Gravity.CENTER)
                        local subParams = LinearLayout.LayoutParams(-1, -2)
                        subParams.setMargins(0, 0, 0, 60)
                        subtitle.setLayoutParams(subParams)
                        layout.addView(subtitle)
                        
                        local versionLayout = LinearLayout(ctx)
                        versionLayout.setOrientation(0)
                        local vParams = LinearLayout.LayoutParams(-1, -2)
                        vParams.setMargins(0, 0, 0, 30)
                        versionLayout.setLayoutParams(vParams)
                        
                        local vCurrent = TextView(ctx)
                        vCurrent.setText("Versi saat ini:\n" .. currentVersion)
                        vCurrent.setTextSize(14)
                        vCurrent.setTextColor(Color.parseColor("#6B7280"))
                        vCurrent.setGravity(Gravity.LEFT)
                        local vcParams = LinearLayout.LayoutParams(0, -2, 1)
                        vCurrent.setLayoutParams(vcParams)
                        versionLayout.addView(vCurrent)
                        
                        local vLatest = TextView(ctx)
                        vLatest.setText("Versi terbaru:\n" .. latestVersion)
                        vLatest.setTextSize(14)
                        vLatest.setTextColor(Color.parseColor("#10B981"))
                        vLatest.setGravity(Gravity.RIGHT)
                        local vlParams = LinearLayout.LayoutParams(0, -2, 1)
                        vLatest.setLayoutParams(vlParams)
                        versionLayout.addView(vLatest)
                        
                        layout.addView(versionLayout)
                        
                        local dateRowLayout = LinearLayout(ctx)
                        dateRowLayout.setOrientation(0)
                        local drParams = LinearLayout.LayoutParams(-1, -2)
                        drParams.setMargins(0, 0, 0, 60)
                        dateRowLayout.setLayoutParams(drParams)
                        
                        local tvUpdateDate = TextView(ctx)
                        tvUpdateDate.setText("Tanggal pembaruan:\n" .. updateDate)
                        tvUpdateDate.setTextSize(14)
                        tvUpdateDate.setTextColor(Color.parseColor("#6B7280"))
                        tvUpdateDate.setGravity(Gravity.LEFT)
                        local udParams = LinearLayout.LayoutParams(0, -2, 1)
                        tvUpdateDate.setLayoutParams(udParams)
                        dateRowLayout.addView(tvUpdateDate)
                        
                        local tvExpiryDate = TextView(ctx)
                        tvExpiryDate.setText("Versi saat ini akan kadaluarsa pada:\n" .. expiryDate)
                        tvExpiryDate.setTextSize(14)
                        tvExpiryDate.setTextColor(Color.parseColor("#EF4444"))
                        tvExpiryDate.setGravity(Gravity.RIGHT)
                        local edParams = LinearLayout.LayoutParams(0, -2, 1)
                        tvExpiryDate.setLayoutParams(edParams)
                        dateRowLayout.addView(tvExpiryDate)
                        
                        layout.addView(dateRowLayout)
                        
                        local whatsNewTitle = TextView(ctx)
                        whatsNewTitle.setText("Apa yang baru:")
                        whatsNewTitle.setTextSize(16)
                        whatsNewTitle.setTextColor(Color.parseColor("#1F2937"))
                        local wntParams = LinearLayout.LayoutParams(-1, -2)
                        wntParams.setMargins(0, 0, 0, 10)
                        whatsNewTitle.setLayoutParams(wntParams)
                        layout.addView(whatsNewTitle)
                        
                        local whatsNew = TextView(ctx)
                        whatsNew.setText(changelog)
                        whatsNew.setTextSize(14)
                        whatsNew.setTextColor(Color.parseColor("#4B5563"))
                        local wnParams = LinearLayout.LayoutParams(-1, -2)
                        wnParams.setMargins(0, 0, 0, 40)
                        whatsNew.setLayoutParams(wnParams)
                        layout.addView(whatsNew)
                        
                        scroll.addView(layout)
                        rootFrame.addView(scroll)
                        
                        local bottomBar = LinearLayout(ctx)
                        bottomBar.setOrientation(0)
                        bottomBar.setGravity(Gravity.CENTER)
                        bottomBar.setBackgroundColor(Color.parseColor("#FFFFFF"))
                        bottomBar.setPadding(40, 30, 40, 30)
                        local bbParams = FrameLayout.LayoutParams(-1, -2)
                        bbParams.gravity = Gravity.BOTTOM
                        bottomBar.setLayoutParams(bbParams)
                        
                        local dialog = AlertDialog.Builder(ctx)
                        dialog.setView(rootFrame)
                        dialog.setCancelable(false)
                        local alert = dialog.create()
                        
                        local btnCancel = Button(ctx)
                        btnCancel.setText("Lain kali")
                        btnCancel.setAllCaps(false)
                        btnCancel.setTextColor(Color.parseColor("#FFFFFF"))
                        btnCancel.setTextSize(16)
                        local btnCanBg = GradientDrawable()
                        btnCanBg.setColor(Color.parseColor("#EF4444"))
                        btnCanBg.setCornerRadius(15)
                        btnCancel.setBackgroundDrawable(btnCanBg)
                        local btnCanParams = LinearLayout.LayoutParams(0, -2, 1)
                        btnCanParams.setMargins(0, 0, 15, 0)
                        btnCancel.setLayoutParams(btnCanParams)
                        
                        btnCancel.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                            onClick = function(v)
                                alert.dismiss()
                            end
                        }))
                        bottomBar.addView(btnCancel)
                        
                        local btnUpdate = Button(ctx)
                        btnUpdate.setText("Perbarui")
                        btnUpdate.setAllCaps(false)
                        btnUpdate.setTextColor(Color.parseColor("#FFFFFF"))
                        btnUpdate.setTextSize(16)
                        local btnUpBg = GradientDrawable()
                        btnUpBg.setColor(Color.parseColor("#3B82F6"))
                        btnUpBg.setCornerRadius(15)
                        btnUpdate.setBackgroundDrawable(btnUpBg)
                        local btnUpParams = LinearLayout.LayoutParams(0, -2, 1)
                        btnUpParams.setMargins(15, 0, 0, 0)
                        btnUpdate.setLayoutParams(btnUpParams)
                        
                        btnUpdate.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                            onClick = function(v)
                                alert.dismiss()
                                startUpdateDownload()
                            end
                        }))
                        bottomBar.addView(btnUpdate)
                        
                        rootFrame.addView(bottomBar)
                        
                        alert.getWindow().setType(2032)
                        alert.show()
                        local window = alert.getWindow()
                        window.setLayout(-1, -1)
                        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                        window.getDecorView().setPadding(0, 0, 0, 0)
                    end
                }))
            end
        end
    end
})).start()