import Cocoa
import CoreAudio

final class FoxView: NSView {
    static let walkFrames: [[NSImage?]] = (0..<3).map { animal in
        (0..<6).map { frame in
            let filename="\(animal)-\(frame).png"
            let candidates=[Bundle.main.resourceURL?.appendingPathComponent("Walk/"+filename),
                URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("outputs/Tilki.app/Contents/Resources/Walk/"+filename),
                URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("Assets/Walk/"+filename)]
            return candidates.compactMap { $0 }.compactMap { NSImage(contentsOf:$0) }.first
        }
    }
    var walkFrameIndex:Int { Int(phase * (animal == 2 ? 3 : 4.5)) % 6 }
    var hovered = false
    var gaze: CGFloat = 0
    var dragged = false
    var hoverStart: CGFloat = -100
    var lastHello: CGFloat = -100
    var habit = ""
    var habitUntil: CGFloat = 0
    var onPet: (() -> Void)?
    var onOpen: (() -> Void)?
    var tracking: NSTrackingArea?
    var hitMask: NSBitmapImageRep?
    var maskTime: CGFloat = -100
    func opaque(at point:NSPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        if hitMask == nil || phase-maskTime > 0.12 {
            let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:180,pixelsHigh:185,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
            NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
            draw(NSRect(x:0,y:0,width:180,height:185)); NSGraphicsContext.restoreGraphicsState()
            hitMask=bitmap; maskTime=phase
        }
        return (hitMask?.colorAt(x:max(0,min(179,Int(point.x))),y:max(0,min(184,184-Int(point.y))))?.alphaComponent ?? 0) > 0.1
    }
    var animal = 0
    var activity = ""
    var affection: CGFloat = 0
    var listening = false
    var typing = false
    var phase: CGFloat = 0
    var wakeUntil: CGFloat = 0
    var sleeping = false {
        didSet { if oldValue != sleeping { hitMask=nil }; if oldValue && !sleeping { wakeUntil=phase+0.8 } }
    }
    var walking = false
    var facing: CGFloat = 1
    var dragStart = NSPoint.zero
    var windowStart = NSPoint.zero
    var onDrag: (() -> Void)?
    var onDrop: (() -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func mouseDown(with event: NSEvent) {
        dragged=false
        if event.clickCount == 2 { onOpen?(); return }
        dragStart = NSEvent.mouseLocation
        windowStart = window!.frame.origin
    }
    override func mouseDragged(with event: NSEvent) {
        let p = NSEvent.mouseLocation
        guard hypot(p.x-dragStart.x,p.y-dragStart.y) > 4 || dragged else { return }
        if !dragged { dragged=true; onDrag?() }
        window?.setFrameOrigin(NSPoint(x: windowStart.x+p.x-dragStart.x, y: windowStart.y+p.y-dragStart.y))
    }
    override func mouseUp(with event: NSEvent) {
        if dragged { onDrop?() } else if event.clickCount == 1 { onPet?() }
    }
    override func rightMouseDown(with event: NSEvent) {
        if let menu = (NSApp.delegate as? AppDelegate)?.status.menu { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }
    func rect(_ x: CGFloat,_ y: CGFloat,_ w: CGFloat,_ h: CGFloat,_ color: NSColor) { guard w > 0, h > 0 else { return }
        let grid:CGFloat=3
        let px=(x/grid).rounded()*grid, py=(y/grid).rounded()*grid
        let pw=max(grid,(w/grid).rounded()*grid), ph=max(grid,(h/grid).rounded()*grid)
        color.setFill(); NSBezierPath(rect:NSRect(x:px,y:py,width:pw,height:ph)).fill() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill(); dirtyRect.fill(using: .copy)
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.setShouldAntialias(false)
        let ink = NSColor(calibratedRed:0.19,green:0.12,blue:0.16,alpha:1)
        let fur = animal == 0 ? NSColor(calibratedRed:0.94,green:0.48,blue:0.23,alpha:1) : animal == 1 ? NSColor(calibratedRed:0.64,green:0.60,blue:0.78,alpha:1) : NSColor(calibratedRed:0.96,green:0.88,blue:0.79,alpha:1)
        let palette: [Character:NSColor] = ["#":ink,"o":fur,"c":NSColor(calibratedRed:1,green:0.92,blue:0.75,alpha:1),"p":NSColor(calibratedRed:0.97,green:0.63,blue:0.64,alpha:1),"h":fur.blended(withFraction:0.25,of:.white)!,"s":fur.blended(withFraction:0.23,of:ink)!,"w":.white]
        // Hand-authored pixel sprites: each character is exactly one square pixel.
        let fox = [
        ".....##..........##.....",
        ".....#o#........#o#.....",
        ".....#oo#......#oo#.....",
        ".....#opo######opo#.....",
        ".....#opoooooooo po#....".replacingOccurrences(of:" ",with:""),
        "....#oohhhhhhhhhooo#....",
        "....#ohhhhhhhhhhhho#....",
        "...#oohhooooooohhoo#....",
        "...#oooo#oooo#ooooo#....",
        "..#oooco#oooo#ocooo o#..".replacingOccurrences(of:" ",with:""),
        "..#ooppcwoooowcppooo#...",
        "...#cccccc##cccccc#....",
        "....#cccccccccccc#.....",
        ".....##cccccccc##......",
        "......#occcccco#.......",
        "......#occccccoo#......",
        ".....#ooccccccooo#.....",
        ".....#ooccccccooo#..##.",
        ".....#sooccccooos#.#oc#",
        ".....#ssoocoooss#.#occ#",
        ".....#ss#ooo#ss#.#occc#",
        ".....#ss#ooo#ss##ooocc#",
        "....#sss#oo#sss#ooocc#.",
        "....###############...."]
        let cat = [
        "....##..........##.....",
        "....#o##......##o#.....",
        "....#opo######opo#.....",
        "....#opoooooooo po#....".replacingOccurrences(of:" ",with:""),
        "...#oohhhhsshhhhoo#....",
        "...#ohhhhsssshhhho#....",
        "...#ooooooss ooooo#....".replacingOccurrences(of:" ",with:""),
        "...#ooo#oooooo#ooo#....",
        "..#oooc#oooooo#cooo#...",
        "..#oppcwoooooowcppo#...",
        "...#ccccccpcccccc#....",
        "....#cccc#c#cccc#.....",
        ".....##ccccccc##......",
        "......#occccco#.......",
        "......#occcccoo#......",
        ".....#oocccccooo#.....",
        ".....#oocccccooo#..###",
        ".....#soocccooos#.#oo#",
        ".....#ss#ooo#ss#..#os#",
        ".....#ss#ooo#ss###os#.",
        "....#sss#oo#sss#oos#..",
        "....###############..."]
        let bunny = [
        ".....###....###........",
        "....#oco#..#oco#.......",
        "....#opo#..#opo#.......",
        "....#opo#..#opo#.......",
        "....#opo#..#opo#.......",
        "....#opo####opo#.......",
        "....#oohhhhhhoo#.......",
        "...#ohhhhhhhhhho#......",
        "..#ohhhhhhhhhhhho#.....",
        "..#oooo#oooo#oooo#.....",
        "..#oooc#oooo#cooo#.....",
        "..#oppcwoooowcppo#.....",
        "...#cccccpccccc#.......",
        "....#cccccccc c#.......".replacingOccurrences(of:" ",with:""),
        ".....##ccwcc##.........",
        "......#occcco#.........",
        ".....#ooccccoo#........",
        ".....#ooccccooo#.###...",
        ".....#ooccccooo##ccc#..",
        ".....#sooccooos#cccc#..",
        "....#cccc##cccc#ccc#...",
        "....###############...."]
        var original = animal == 0 ? fox : animal == 1 ? cat : bunny
        // Edit only the exact eye pixels; keep cheeks and muzzle untouched.
        let blinkTime=(phase+CGFloat(animal)*0.23).truncatingRemainder(dividingBy:2.8)
        if !sleeping && blinkTime > 2.56 {
            let top=animal == 0 ? 8 : animal == 1 ? 7 : 9
            let columns=animal == 0 ? [8,13] : animal == 1 ? [7,14] : [7,12]
            for r in top...top+2 {
                var line=Array(original[r])
                for c in columns {
                    line[c] = r == top ? "o" : r == top+2 ? "c" : (blinkTime > 2.62 && blinkTime < 2.74 ? "-" : "#")
                }
                original[r]=String(line)
            }
        }
        let moving = walking && !sleeping && !typing && !listening
        let unit: CGFloat = 6
        func sprite(_ data:[String], x:CGFloat, y:CGFloat, pixel:CGFloat) {
            for (row,line) in data.enumerated() {
                for (col,key) in line.enumerated() {
                    if key == "-" { rect(x+CGFloat(col)*pixel,y+CGFloat(data.count-1-row)*pixel,pixel,3,ink) }
                    else if let color=palette[key] { rect(x+CGFloat(col)*pixel,y+CGFloat(data.count-1-row)*pixel,pixel,pixel,color) }
                }
            }
        }
        // Keep the approved face intact in every pose. Only the body and limbs change.
        if moving, let image=Self.walkFrames[animal][walkFrameIndex] {
            ctx.saveGState();ctx.translateBy(x:90,y:0);ctx.scaleBy(x:facing,y:1)
            ctx.interpolationQuality = .none
            image.draw(in:NSRect(x:-90,y:0,width:180,height:186),from:.zero,operation:.sourceOver,fraction:1)
            ctx.restoreGState(); return
        }
        if sleeping {
            ctx.saveGState(); ctx.translateBy(x:90,y:18); ctx.scaleBy(x:facing,y:1)
            let cream=palette["c"]!, highlight=palette["h"]!
            func blockOval(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ color:NSColor) {
                let inset=min(6,min(w,h)/4)
                rect(x+inset*2,y,w-inset*4,h,color); rect(x+inset,y+inset,w-inset*2,h-inset*2,color); rect(x,y+inset*2,w,h-inset*4,color)
            }
            let headCount=animal == 0 ? 14 : animal == 1 ? 13 : 15
            var head=Array(original.prefix(headCount))
            if sleeping {
                let eyeRow=animal == 0 ? 8 : animal == 1 ? 7 : 9
                
                for r in eyeRow...min(head.count-1,eyeRow+2) {
                    var line=Array(head[r])
                    for c in 5..<min(17,line.count) {
                        if line[c] == "#" || line[c] == "w" { line[c] = r == eyeRow+2 ? "c" : "o" }
                    }
                    head[r]=String(line)
                }
                let breath:CGFloat = sin(phase*1.5)>0.4 ? 2 : 0
                blockOval(-15,0,86,64+breath,ink)
                blockOval(-9,6,74,52+breath,fur)
                rect(9,48+breath,36,6,highlight)
                // Folded paws form a pillow beneath the familiar face.
                blockOval(-57,0,54,18,ink); rect(-51,6,42,6,cream)
                if animal == 2 {
                    // Fold the ears backward, instead of shrinking the face.
                    head=Array(head.dropFirst(6))
                }
                if animal == 2 {
                    // Ears grow from the rear crown and drape along the back.
                    // Draw behind the head so the roots merge into its silhouette.
                    let ears = [
                        "..######.....",
                        ".#ccppcc##...",
                        "#cccppppcc#..",
                        "#ccccccccc#..",
                        ".###cccccc##.",
                        "....#ccpppcc#",
                        ".....#cccccc#",
                        "......######."]
                    sprite(ears,x:-24,y:30,pixel:6)
                }
                sprite(head,x:-72,y:12,pixel:6)
                let eyeY = CGFloat(head.count-(eyeRow-(animal == 2 ? 6 : 0))-2)*6+12
                for x:CGFloat in [-30,animal == 1 ? 12 : 0] {
                    rect(x-5,eyeY+3,5,3,ink); rect(x,eyeY,10,3,ink); rect(x+10,eyeY+3,5,3,ink)
                }
                if animal == 0 {
                    // Curled tail: every edge follows the same square pixel grid.
                    let tail = [
                        ".............###",
                        "............#oo#",
                        "...........#ooo#",
                        "..........#ooo#.",
                        ".#########oooo#.",
                        "#ccccoooooooos#.",
                        "#cccoooooooss#..",
                        ".#ccoooossss#...",
                        "..##########...."]
                    sprite(tail,x:-12,y:0,pixel:6)
                } else if animal == 1 {
                    let tail = [
                        "..........###",
                        "..........#o#",
                        "..........#o#",
                        "..........#o#",
                        ".##########o#",
                        "#sssssoooooo#",
                        ".###########."]
                    sprite(tail,x:-6,y:0,pixel:6)
                } else {
                    blockOval(54,6,24,24,ink); rect(60,12,12,12,cream)
                }
            }
            ctx.restoreGState()
            if sleeping { sprite(["###","..#",".#.","#..","###"],x:144,y:105+round(sin(phase))*3,pixel:3) }
            return
        }
        ctx.saveGState(); ctx.translateBy(x:90,y:18 + (listening && !typing ? round(sin(phase*3)*2) : 0)); ctx.scaleBy(x:facing,y:1)
        if wakeUntil > phase && !typing {
            let t=max(0,min(1,(wakeUntil-phase)/0.8))
            ctx.translateBy(x:0,y:round(sin(t * .pi)*4))
        }
        let eating=activity == "food" && affection > 0
        ctx.saveGState()
        if eating { ctx.translateBy(x:0,y:-round(abs(sin(phase*7))*5)) }
        sprite(original,x:-72,y:0,pixel:unit)
        ctx.restoreGState()
        if eating {
            // Food recedes as the pal eats from a real little bowl.
            rect(-30,-3,60,18,ink); rect(-24,0,48,9,NSColor(calibratedRed:0.40,green:0.70,blue:0.68,alpha:1))
            let amount=ceil(min(1,affection/5)*5)
            for i in 0..<Int(amount) { rect(-22+CGFloat(i)*9,15,6,4,animal == 2 ? palette["p"]! : palette["s"]!) }
            rect(-21,3,12,3,.white)
        }
        if activity == "play" && affection > 0 {
            let ballX=sin(phase*5)*39
            let ballY=6+abs(sin(phase*5))*15
            rect(ballX-9,ballY,18,18,ink); rect(ballX-6,ballY+3,12,12,palette["p"]!)
            rect(ballX-3,ballY+9,6,3,.white)
            let pawX=ballX > 0 ? CGFloat(18) : -36
            rect(pawX,21,18,12,ink); rect(pawX+3,24,12,6,fur)
        }
        if habitUntil > phase && !typing && !listening {
            if animal == 1 { // A paw washes one cheek.
                let y:CGFloat=84+round(sin(phase*9))*3
                rect(-36,57,15,y-51,ink); rect(-33,60,9,y-54,fur)
                rect(-42,y,18,18,ink); rect(-39,y+3,12,12,fur)
            } else if animal == 2 { // A tiny nose twitch.
                rect(-9,54,9,3,palette["p"]!); rect(-6+round(sin(phase*12))*2,57,3,3,ink)
            } else { // A bashful tail-side paw and a sparkle.
                rect(27,24,18,12,ink); rect(30,27,12,6,fur)
                rect(57,48,3,9,palette["c"]!); rect(54,51,9,3,palette["c"]!)
            }
        }
        if listening && !sleeping {
            // Each species has its own crown / cheek anchors; rabbit ears remain free.
            let crown:CGFloat = [114,102,96][animal]
            // Ear-cup shells have 27pt width. Their centers, rather than
            // their left edges, must mirror the center of each face.
            let faceCenter:CGFloat = animal == 1 ? -6 : -9
            let left:CGFloat = animal == 0 ? -63 : faceCenter-60
            let right:CGFloat = animal == 0 ? 45 : faceCenter+42
            let accent = animal == 0 ? NSColor(calibratedRed:0.43,green:0.77,blue:0.73,alpha:1) : animal == 1 ? NSColor(calibratedRed:0.90,green:0.67,blue:0.79,alpha:1) : NSColor(calibratedRed:0.61,green:0.73,blue:0.92,alpha:1)
            let cushion=NSColor(calibratedRed:0.30,green:0.28,blue:0.37,alpha:1)
            if animal == 0 {
            // Rounded stepped headband with a soft inner pad.
            rect(left+12,crown+6,right-left-12,9,ink)
            rect(left+6,crown,12,12,ink);rect(right-6,crown,12,12,ink)
            rect(left+15,crown+9,right-left-18,3,accent)
            rect(left+15,crown+3,right-left-18,3,cushion)
            rect(left+6,crown-21,6,24,ink);rect(right,crown-21,6,24,ink)
            for x in [left-6,right-3] {
                // Cushions face inward; shells are inset instead of square blocks.
                rect(x+3,crown-45,21,33,ink);rect(x,crown-39,27,21,ink)
                rect(x+6,crown-42,15,27,cushion)
                rect(x+6,crown-36,15,18,accent)
                rect(x+9,crown-21,9,3,.white)
                // Decorative equalizer, not a measurement of the playing audio.
                for bar in 0..<3 {
                    let height=CGFloat(1+(Int(phase*5)+bar*2)%3)*3
                    rect(x+6+CGFloat(bar)*6,crown-36,3,height,cushion)
                }
            }
            } else {
                // One mirrored construction for both cups and the headband.
                let c=faceCenter
                rect(c-45,crown+6,90,9,ink)
                rect(c-54,crown-3,12,15,ink); rect(c+42,crown-3,12,15,ink)
                rect(c-42,crown+9,84,3,accent)
                rect(c-42,crown+3,84,3,cushion)
                for side:CGFloat in [-1,1] {
                    let center=c+side*54
                    rect(center-3,crown-24,6,24,ink)
                    rect(center-9,crown-48,18,33,ink)
                    rect(center-12,crown-42,24,21,ink)
                    rect(center-6,crown-45,12,27,cushion)
                    rect(center-6,crown-39,12,18,accent)
                    rect(center-3,crown-24,6,3,.white)
                    for bar in 0..<2 {
                        let height=CGFloat(1+(Int(phase*5)+bar)%3)*3
                        rect(center-6+CGFloat(bar)*6,crown-39,3,height,cushion)
                    }
                }
            }
            if !typing {
                // Tiny floating pixel notes, kept inside the pet canvas.
                let rise=CGFloat(Int(phase*6)%15)
                let x:CGFloat = 68, y:CGFloat = 120+rise
                rect(x,y,6,6,accent);rect(x+3,y+3,3,12,accent);rect(x+6,y+12,6,3,accent)
            }
        }

        if typing && !sleeping {
            let shell = NSColor(calibratedRed:0.65,green:0.64,blue:0.75,alpha:1)
            rect(-60,-6,120,36,ink); rect(-57,0,114,27,shell)
            rect(-54,-3,108,3,NSColor.darkGray)
            for row in 0..<3 {
                for col in 0..<11 {
                    let x = CGFloat(-51+col*9), y = CGFloat(20-row*7)
                    rect(x,y,6,5,ink); rect(x,y+2,6,3,.white)
                }
            }
            rect(-48,1,12,4,ink); rect(-27,1,48,4,ink); rect(-24,3,42,2,.white)
            rect(30,1,9,4,ink); rect(42,1,9,4,ink)
            let tap = round(sin(phase*18))*3
            rect(-30,24+tap,18,12,ink); rect(-27,27+tap,12,9,fur)
            rect(15,24-tap,18,12,ink); rect(18,27-tap,12,9,fur)
        }
        ctx.restoreGState()
        if affection > 0 && activity != "food" && activity != "play" {
            let heart=[".##.##.","#######","#######",".#####.","..###..","...#..."]
            let color=NSColor(calibratedRed:0.86,green:0.29,blue:0.44,alpha:1)
            for (r,line) in heart.enumerated() { for (c,key) in line.enumerated() where key == "#" {
                rect(78+CGFloat(c)*3,159-CGFloat(r)*3+round(sin(phase*3))*3,3,3,color)
            }}
        }
    }

}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel!
    var fox: FoxView!
    var status: NSStatusItem!
    let preferences: UserDefaults
    init(preferences: UserDefaults = .standard) { self.preferences=preferences; super.init(); careEnabled=preferences.bool(forKey:"careEnabled") }
    var careEnabled = false
    var animalButtons: [NSButton] = []
    var wanderButton: NSButton?
    var lastSave = 0.0
    var messageUntil = 0.0
    var fullness = 85.0
    var energy = 85.0
    var playButton: NSButton?
    var sleepButton: NSButton?
    var affectionLevel = 85.0
    var careLabel: NSTextField?
    var feedbackLabel: NSTextField?
    var foodButton: NSButton?
    var petButton: NSButton?
    var mediaCheck = 0.0
    var audioStarted: Double?
    var audioStopped: Double?
    var manualSleep = false
    var controls: NSWindow?
    var timer: Timer?
    var last = ProcessInfo.processInfo.systemUptime
    var elapsed: Double = 0
    var nextAction: Double = 5
    var direction: CGFloat = 1
    var lastMouse = NSEvent.mouseLocation
    var lastMouseTime = ProcessInfo.processInfo.systemUptime
    var roaming = true
    var draggingUntil: Double = 0
    var sizePicker: NSPopUpButton?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        window = NSPanel(contentRect:NSRect(x:300,y:100,width:180,height:185),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        window.isOpaque = false; window.backgroundColor = .clear; window.hasShadow = false
        window.level = .floating; window.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary]; window.isMovableByWindowBackground = false
        fox = FoxView(frame:NSRect(x:0,y:0,width:180,height:185)); window.contentView = fox
        fox.animal=max(0,min(2,preferences.integer(forKey:"selectedAnimal")))
        roaming=preferences.object(forKey:"roaming") as? Bool ?? true
        loadCare()
        applySize(preferences.object(forKey:"petSize") as? Double ?? 1)
        fox.onPet = { [weak self] in self?.greet() }
        fox.onOpen = { [weak self] in self?.showControls() }
        fox.onDrop = { [weak self] in
            guard let self else { return }; self.clampPosition()
            self.preferences.set([self.window.frame.origin.x,self.window.frame.origin.y],forKey:"position")
        }
        NotificationCenter.default.addObserver(self,selector:#selector(clampPosition),name:NSApplication.didChangeScreenParametersNotification,object:nil)
        fox.onDrag = { [weak self] in self?.manualSleep=false; self?.fox.sleeping=false; self?.draggingUntil = ProcessInfo.processInfo.systemUptime + 10; self?.fox.walking = false }
        if let screen = NSScreen.main { window.setFrameOrigin(NSPoint(x:screen.visibleFrame.midX,y:screen.visibleFrame.minY)) }
        if let p=preferences.array(forKey:"position") as? [Double], p.count==2, p.allSatisfy({$0.isFinite}) {
            window.setFrameOrigin(NSPoint(x:p[0],y:p[1])); clampPosition()
        }
        window.orderFrontRegardless()
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength); status.button?.title = ["🦊","🐱","🐰"][fox.animal]
        let menu = NSMenu()
        add(menu,"Old MacDonald’s Desktop Farm · Your desktop companion",nil)
        menu.addItem(.separator())
        add(menu,"Old MacDonald’s Desktop Farm…",#selector(showControls))
        add(menu,"Switch pal: Fox → Cat → Bunny",#selector(changeAnimal))
        add(menu,"Toggle wandering",#selector(toggleRoaming))
        add(menu,"Sleep / Wake",#selector(toggleSleep))
        add(menu,"Bring here",#selector(bringBack))
        add(menu,"Hide / Show",#selector(toggleVisible))
        menu.addItem(.separator()); add(menu,"Quit Old MacDonald’s Desktop Farm",#selector(quit))
        status.menu = menu
        showControls()
        timer = Timer(timeInterval:1/24.0,repeats:true) { [weak self] _ in self?.tick() }
        timer?.tolerance=0.008
        RunLoop.main.add(timer!,forMode:.common)
    }
    func add(_ menu:NSMenu,_ title:String,_ action:Selector?) { let item = NSMenuItem(title:title,action:action,keyEquivalent:""); item.target = self; menu.addItem(item) }
    @objc func showControls() {
        if let controls { controls.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true); return }
        let panel = NSWindow(contentRect:NSRect(x:0,y:0,width:440,height:650),styleMask:[.titled,.closable],backing:.buffered,defer:false)
        panel.title = "Old MacDonald’s Desktop Farm"; panel.isReleasedWhenClosed = false
        panel.appearance = NSAppearance(named:.aqua)
        panel.backgroundColor = NSColor(calibratedRed:0.98,green:0.96,blue:0.92,alpha:1)
        let root = panel.contentView!
        func label(_ text:String,_ y:CGFloat,_ size:CGFloat) -> NSTextField {
            let l = NSTextField(labelWithString:text); l.font = .systemFont(ofSize:size,weight:size > 20 ? .bold : .medium)
            l.textColor = NSColor(calibratedRed:0.22,green:0.17,blue:0.22,alpha:1)
            l.frame = NSRect(x:26,y:y,width:392,height:32); root.addSubview(l); return l
        }
        _ = label("Your pocket-sized best friend.",520,23)
        _ = label("Click to pet. Drag to move. Double-click for home.",487,12)
        for (i,name) in ["🦊  Maple","🐱  Mochi","🐰  Clover"].enumerated() {
            let b = NSButton(title:name,target:self,action:#selector(selectAnimal(_:))); b.tag=i; b.bezelStyle = .rounded
            b.frame=NSRect(x:24+i*132,y:429,width:128,height:44); root.addSubview(b); b.setButtonType(.pushOnPushOff); animalButtons.append(b)
        }
        let walk = NSButton(checkboxWithTitle:"Let my pal wander",target:self,action:#selector(setRoaming(_:))); walk.state = roaming ? .on : .off
        walk.frame=NSRect(x:28,y:391,width:370,height:26); root.addSubview(walk); wanderButton=walk
        let care = NSButton(checkboxWithTitle:"Virtual pet mode",target:self,action:#selector(setCare(_:))); care.state = careEnabled ? .on : .off
        care.frame=NSRect(x:28,y:352,width:380,height:26); root.addSubview(care)
        _ = label("Feed, play, cuddle, nap. Your own tiny daily ritual.",317,12)
        careLabel = label("",218,14)
        careLabel?.frame.size.height=94
        careLabel?.font = .monospacedSystemFont(ofSize:14,weight:.bold)
        careLabel?.maximumNumberOfLines=4
        careLabel?.drawsBackground=true
        careLabel?.backgroundColor=NSColor(calibratedRed:0.83,green:0.89,blue:0.73,alpha:1)

        let food = NSButton(title:"🍎  Feed",target:self,action:#selector(feed)); food.bezelStyle = .rounded
        food.frame=NSRect(x:24,y:175,width:190,height:36); root.addSubview(food); foodButton=food
        let pet = NSButton(title:"♥  Cuddle",target:self,action:#selector(pet)); pet.bezelStyle = .rounded
        pet.frame=NSRect(x:224,y:175,width:190,height:36); root.addSubview(pet); petButton=pet
        let play = NSButton(title:"✦  Play",target:self,action:#selector(play)); play.bezelStyle = .rounded; play.frame=NSRect(x:24,y:135,width:190,height:36); root.addSubview(play); playButton=play
        let sleep = NSButton(title:"☾  Sleep / Wake",target:self,action:#selector(toggleSleep)); sleep.bezelStyle = .rounded; sleep.frame=NSRect(x:224,y:135,width:190,height:36); root.addSubview(sleep); sleepButton=sleep
        feedbackLabel = label("",99,13)
        _ = label("Your pal rests while you are away. No offline decay.",65,11)
        let back = NSButton(title:"Bring here",target:self,action:#selector(bringBack)); back.bezelStyle = .rounded; back.frame=NSRect(x:24,y:25,width:145,height:32); root.addSubview(back)
        let quitButton = NSButton(title:"Quit",target:self,action:#selector(quit)); quitButton.bezelStyle = .rounded; quitButton.frame=NSRect(x:324,y:25,width:90,height:32); root.addSubview(quitButton)
        for child in root.subviews { child.frame.origin.y += 70 }
        let size=NSPopUpButton(frame:NSRect(x:26,y:36,width:135,height:28)); size.addItems(withTitles:["Small","Medium","Large"]); size.target=self; size.action=#selector(changeSize(_:))
        let scale=preferences.object(forKey:"petSize") as? Double ?? 1
        size.selectItem(at:scale < 0.9 ? 0 : scale > 1.1 ? 2 : 1); root.addSubview(size); sizePicker=size
        controls=panel; refreshCare(); panel.center(); panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true)
    }
    func applySize(_ value:Double) {
        let scale=max(0.75,min(1.25,value))
        guard let window, let fox else { return }
        let origin=window.frame.origin
        window.setContentSize(NSSize(width:180*scale,height:185*scale))
        fox.frame=NSRect(x:0,y:0,width:180*scale,height:185*scale); fox.bounds=NSRect(x:0,y:0,width:180,height:185)
        window.setFrameOrigin(origin); clampPosition()
    }
    @objc func changeSize(_ sender:NSPopUpButton) {
        let value=[0.75,1.0,1.25][sender.indexOfSelectedItem]; preferences.set(value,forKey:"petSize"); applySize(value)
    }
    @objc func toggleGaze(_ sender:NSButton) { preferences.set(sender.state == .on,forKey:"cursorGaze"); fox.gaze=0 }
    func refreshCare() {
        for b in animalButtons { b.state=b.tag == fox.animal ? .on : .off }
        wanderButton?.state=roaming ? .on : .off
        sleepButton?.title=fox.sleeping ? "☀  Wake up" : "☾  Sleep"

        foodButton?.isEnabled=careEnabled; petButton?.isEnabled=careEnabled; playButton?.isEnabled=careEnabled; sleepButton?.isEnabled=true
        func meter(_ value:Double) -> String { let n=max(0,min(10,Int(value/10))); return String(repeating:"▰",count:n)+String(repeating:"▱",count:10-n) }
        careLabel?.stringValue = careEnabled ? " FOOD  \(meter(fullness))  \(Int(fullness))\n JOY   \(meter(affectionLevel))  \(Int(affectionLevel))\n REST  \(meter(energy))  \(Int(energy))" : "\n  COMPANION MODE\n  No needs. Just your little friend."

        if elapsed < messageUntil { return }
        if !careEnabled { feedbackLabel?.stringValue="Simply happy to be here with you." }
        else if fullness < 30 { feedbackLabel?.stringValue="A little snack would be lovely." }
        else if affectionLevel < 30 { feedbackLabel?.stringValue="Someone would love a little cuddle." }
        else if energy < 25 { feedbackLabel?.stringValue="A cozy nap sounds lovely." }
        else { feedbackLabel?.stringValue=fox.sleeping ? "Curled up, dreaming of tiny adventures." : "Happy paws. Happy little day." }
    }
    @objc func setCare(_ sender:NSButton) {
        careEnabled=sender.state == .on; preferences.set(careEnabled,forKey:"careEnabled")
        feedbackLabel?.stringValue=careEnabled ? "Snacks and cuddles, whenever you feel like it." : "Simply happy to be here with you."
        refreshCare()
    }
    func greet() {
        manualSleep=false; fox.sleeping=false; fox.walking=false; fox.typing=false
        lastMouseTime=ProcessInfo.processInfo.systemUptime; nextAction=elapsed+5
        fox.activity="heart"; fox.affection=3; messageUntil=elapsed+5
        if careEnabled { affectionLevel=min(100,affectionLevel+8); saveCare() }
        feedbackLabel?.stringValue="A little head scratch. A very big heart."
        refreshCare()
    }
    @objc func feed() {
        guard careEnabled else { return }; messageUntil=elapsed+5; lastMouseTime=ProcessInfo.processInfo.systemUptime; fullness=min(100,fullness+25); fox.activity="food"; fox.affection=5; fox.walking=false; manualSleep=false; fox.sleeping=false
        feedbackLabel?.stringValue=["Nom nom. That hit the spot!","A tiny snack. A very happy tummy.","Saving a crumb for later. ♥"].randomElement()!; refreshCare(); saveCare()
    }
    @objc func pet() {
        guard careEnabled else { return }; messageUntil=elapsed+5; lastMouseTime=ProcessInfo.processInfo.systemUptime; affectionLevel=min(100,affectionLevel+30); fox.activity="heart"; fox.affection=4; manualSleep=false; fox.sleeping=false
        feedbackLabel?.stringValue=["Leaning into that cuddle. ♥","You just made their whole afternoon.","Tiny paws. Big love."].randomElement()!; refreshCare(); saveCare()
    }
    @objc func play() {
        guard careEnabled else { return }
        messageUntil=elapsed+5
        lastMouseTime=ProcessInfo.processInfo.systemUptime
        guard energy >= 15 else { feedbackLabel?.stringValue="A tiny nap first, then more adventures."; return }
        energy=max(0,energy-8); fullness=max(0,fullness-4); affectionLevel=min(100,affectionLevel+20)
        manualSleep=false; fox.sleeping=false; fox.activity="play"; fox.affection=5; fox.walking=false
        feedbackLabel?.stringValue="A little game of paw-ball. Best day ever!"; refreshCare(); saveCare()
    }
    func saveCare() {
        guard fox != nil else { return }
        preferences.set([fullness,affectionLevel,energy],forKey:"pet.\(fox.animal)")
    }
    func loadCare() {
        let values=preferences.array(forKey:"pet.\(fox.animal)") as? [Double] ?? [85,85,85]
        func bounded(_ index:Int) -> Double { guard values.count > index, values[index].isFinite else { return 85 }; return max(0,min(100,values[index])) }
        fullness=bounded(0); affectionLevel=bounded(1); energy=bounded(2)
    }
    func applicationWillTerminate(_ notification:Notification) { saveCare() }
    func switchAnimal(_ index:Int) {
        saveCare(); fox.animal=max(0,min(2,index)); loadCare()
        preferences.set(fox.animal,forKey:"selectedAnimal")
        fox.affection=0; fox.activity=""; fox.walking=false; fox.needsDisplay=true
        status?.button?.title=["🦊","🐱","🐰"][fox.animal]; messageUntil=0; refreshCare()
    }
    @objc func selectAnimal(_ sender:NSButton) { switchAnimal(sender.tag) }
    @objc func setRoaming(_ sender:NSButton) { roaming=sender.state == .on; fox.walking=false; preferences.set(roaming,forKey:"roaming"); refreshCare() }
    @objc func changeAnimal() { switchAnimal((fox.animal+1)%3) }
    @objc func toggleRoaming() { roaming.toggle(); fox.walking=false; preferences.set(roaming,forKey:"roaming"); refreshCare() }
    @objc func toggleSleep() {
        manualSleep = !fox.sleeping
        lastMouseTime=ProcessInfo.processInfo.systemUptime; fox.sleeping=manualSleep; fox.walking=false; fox.typing=false; fox.affection=0
        nextAction=elapsed+8; refreshCare()
    }
    @objc func clampPosition() {
        guard let window, let screen=window.screen ?? NSScreen.main else { return }
        let bounds=screen.visibleFrame
        var p=window.frame.origin
        p.x=max(bounds.minX,min(p.x,bounds.maxX-window.frame.width))
        p.y=max(bounds.minY,min(p.y,bounds.maxY-window.frame.height))
        window.setFrameOrigin(p)
    }
    @objc func bringBack() { if let s = NSScreen.main { window.setFrameOrigin(NSPoint(x:s.visibleFrame.midX-90,y:s.visibleFrame.minY)) }; window.orderFrontRegardless() }
    @objc func toggleVisible() { window.isVisible ? window.orderOut(nil) : window.orderFrontRegardless() }
    @objc func quit() { NSApp.terminate(nil) }
    func outputActive() -> Bool {
        if #available(macOS 14.2, *) {
            var address = AudioObjectPropertyAddress(mSelector:kAudioHardwarePropertyProcessObjectList,mScope:kAudioObjectPropertyScopeGlobal,mElement:kAudioObjectPropertyElementMain)
            var size: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),&address,0,nil,&size) == noErr else { return false }
            guard size > 0 else { return false }
            var processes = [AudioObjectID](repeating:0,count:Int(size)/MemoryLayout<AudioObjectID>.size)
            let result = processes.withUnsafeMutableBytes { AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),&address,0,nil,&size,$0.baseAddress!) }
            guard result == noErr else { return false }
            for process in processes {
                var running: UInt32 = 0; var count = UInt32(MemoryLayout<UInt32>.size)
                var property = AudioObjectPropertyAddress(mSelector:kAudioProcessPropertyIsRunningOutput,mScope:kAudioObjectPropertyScopeGlobal,mElement:kAudioObjectPropertyElementMain)
                if AudioObjectGetPropertyData(process,&property,0,nil,&count,&running) == noErr && running != 0 { return true }
            }
        }
        return false
    }
    func tick(now:Double = ProcessInfo.processInfo.systemUptime, mouse:NSPoint = NSEvent.mouseLocation, keyboardIdleOverride:Double? = nil) {
         let dt = max(0,min(now-last,0.1)); last = now; elapsed += dt
        fox.phase += dt
        // Empty pixels pass mouse events through to the app underneath.
        if window.isVisible && NSEvent.pressedMouseButtons == 0 {
            let scale=window.frame.width/180
            let local=NSPoint(x:(mouse.x-window.frame.minX)/scale,y:(mouse.y-window.frame.minY)/scale)
            let hit=fox.opaque(at:local)
            window.ignoresMouseEvents = !hit
        }
        if fox.affection > 0 { fox.walking=false }
        if elapsed >= mediaCheck {
            mediaCheck=elapsed+1
            if outputActive() {
                audioStopped=nil
                if audioStarted == nil { audioStarted=elapsed }
                if elapsed-(audioStarted ?? elapsed) >= 2 { fox.listening=true }
            } else {
                audioStarted=nil
                if audioStopped == nil { audioStopped=elapsed }
                if elapsed-(audioStopped ?? elapsed) >= 3 { fox.listening=false }
            }
        }

        fox.affection=max(0,fox.affection-CGFloat(dt))
        if careEnabled {
            fullness=max(0,fullness-dt/90); affectionLevel=max(0,affectionLevel-dt/120)
            energy=max(0,min(100,energy + (fox.sleeping ? dt/2 : -dt/150)))
            if Int(elapsed) != Int(elapsed-dt) { refreshCare() }
            if elapsed-lastSave >= 30 { saveCare(); lastSave=elapsed }
        }
        if manualSleep { fox.sleeping=true; fox.typing=false; fox.needsDisplay=true; return }

        if mouse != lastMouse { lastMouseTime = now; lastMouse = mouse; fox.sleeping = false }
        // Only aggregate idle time is read. No keys or typed text are captured.
        let keyboardIdle = keyboardIdleOverride ?? CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        fox.typing = keyboardIdle < 0.65
        if fox.affection > 0 && (fox.activity == "food" || fox.activity == "play") { fox.typing=false }
        if fox.typing { lastMouseTime=now; fox.sleeping = false; fox.walking = false }
        else if fox.listening { fox.sleeping=false; fox.walking=false }
        else if fox.affection > 0 { fox.sleeping=false; fox.walking=false }
        else if now - lastMouseTime > 35 { fox.sleeping = true; fox.walking = false }

        if now < draggingUntil { fox.needsDisplay = true; return }
        if elapsed > nextAction && fox.affection <= 0 && !fox.typing && !fox.listening && now - lastMouseTime <= 35 {
            let choice = Int.random(in:0...7)
            if choice >= 6 { fox.habitUntil=fox.phase+3; fox.habit="groom" }
            fox.sleeping = choice == 0
            fox.walking = roaming && choice >= 2 && choice < 6
            direction = Bool.random() ? 1 : -1
            nextAction = elapsed + (fox.sleeping ? Double.random(in:20...45) : Double.random(in:4...12))
        }
        if fox.walking && fox.affection <= 0 && !fox.sleeping && window.isVisible {
            let screen = window.screen ?? NSScreen.main!
            let bounds = screen.visibleFrame
            let frame=Int(fox.phase*5) % 6
            let speed:CGFloat = fox.animal == 2 ? ([0,24,36,36,24,0][frame]) : 24
            var p = window.frame.origin; p.x += direction * CGFloat(dt) * speed
            if p.x < bounds.minX { p.x = bounds.minX; direction = 1 }
            if p.x + window.frame.width > bounds.maxX { p.x = bounds.maxX-window.frame.width; direction = -1 }
            fox.facing = direction; window.setFrameOrigin(p)
        }
        if window.isVisible { fox.needsDisplay = true }
    }
}
if CommandLine.arguments.contains("--validate-assets") {
    let count=FoxView.walkFrames.flatMap { $0 }.compactMap { $0 }.count
    print("Walking assets: \(count)/18")
    exit(count == 18 ? 0 : 1)
}
if CommandLine.arguments.contains("--preview") {
    let _ = NSApplication.shared
    let sheet = NSImage(size:NSSize(width:900,height:555))
    sheet.lockFocus()
    NSColor(calibratedRed:0.94,green:0.93,blue:0.90,alpha:1).setFill(); NSRect(x:0,y:0,width:900,height:555).fill()
    for animal in 0..<3 {
        for state in 0..<5 {
            let view = FoxView(frame:NSRect(x:0,y:0,width:180,height:185)); view.animal=animal; view.phase=0.7
            view.sleeping=state == 1; view.walking=state == 2; view.typing=state == 3; view.listening=state == 4
            NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current!.cgContext.translateBy(x:CGFloat(state*180),y:CGFloat((2-animal)*185))
            view.draw(view.bounds); NSGraphicsContext.restoreGraphicsState()
        }
    }
    sheet.unlockFocus()
    let bitmap=NSBitmapImageRep(data:sheet.tiffRepresentation!)!
    try! bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments.last!))
    exit(0)
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
