let app = NSApplication.shared
var checks = 0
func check(_ value:Bool,_ message:String) { checks += 1; if !value { print("FAIL: " + message); exit(1) } }
func render(_ v:FoxView) -> Data {
    let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:180,pixelsHigh:185,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
    v.draw(v.bounds); NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using:.png,properties:[:])!
}
for animal in 0..<3 {
    let v=FoxView(frame:NSRect(x:0,y:0,width:180,height:185)); v.animal=animal
    let idle=render(v)
    for direction:CGFloat in [-1,1] {
        v.facing=direction
        for state in 0..<8 {
            v.sleeping=state == 1 || state == 7; v.walking=state == 2
            v.typing=state == 3 || state == 5 || state == 7; v.listening=state == 4 || state == 5 || state == 7
            v.affection=state == 6 ? 3 : 0
            for phase:CGFloat in [0,0.2,0.5,0.8] {
                v.phase=phase
                let data=render(v); check(!data.isEmpty,"render")
                try! data.write(to:URL(fileURLWithPath:"work/qa/a\(animal)-d\(Int(direction))-s\(state)-p\(phase).png"))
            }
        }
    }
    v.facing=1; v.sleeping=false; v.typing=false; v.listening=false; v.affection=0; v.walking=true
    v.phase=0.2; let step1=render(v); v.phase=0.5; check(step1 != render(v),"walking frames differ animal \(animal)")
    v.walking=false; v.sleeping=true; v.phase=0; let sleep=render(v); check(sleep != idle,"curled pose differs")
    v.typing=true; v.listening=true; check(render(v)==sleep,"sleep suppresses accessories")
    let prefs=UserDefaults(suiteName:"LittlePals.Tests")!; let d=AppDelegate(preferences:prefs); d.fox=v; d.window=NSPanel(contentRect:v.bounds,styleMask:.borderless,backing:.buffered,defer:false)
    d.careEnabled=false; d.fullness=50; d.affectionLevel=50; d.energy=50
    d.feed(); d.pet(); d.play(); check(d.fullness==50 && d.affectionLevel==50 && d.energy==50,"companion has no care effects")
    d.careEnabled=true; d.feed(); check(d.fullness==75,"food gain"); d.pet(); check(d.affectionLevel==80,"cuddle gain")
    d.play(); check(d.energy==42 && d.fullness==71 && d.affectionLevel==100,"play tradeoff")
    d.energy=10; d.play(); check(d.energy==10,"low energy guard")
    d.fullness=99; d.feed(); check(d.fullness==100,"food cap")
    d.manualSleep=false; v.sleeping=false; d.toggleSleep(); check(d.manualSleep && v.sleeping && !v.walking,"manual sleep")
    d.toggleSleep(); check(!d.manualSleep && !v.sleeping,"manual wake")
    d.manualSleep=true; d.mediaCheck=Double.greatestFiniteMagnitude; d.last=ProcessInfo.processInfo.systemUptime-0.1
    d.tick(); check(v.sleeping && !v.typing,"sleep priority tick")
}

let prefs=UserDefaults(suiteName:"LittlePals.AuditTests")!
prefs.removePersistentDomain(forName:"LittlePals.AuditTests")
let d=AppDelegate(preferences:prefs); d.fox=FoxView(frame:NSRect(x:0,y:0,width:180,height:185)); d.window=NSPanel(contentRect:d.fox.bounds,styleMask:.borderless,backing:.buffered,defer:false)
d.fullness=23; d.saveCare(); d.switchAnimal(1); check(d.fullness==85,"new pet independent"); d.fullness=66; d.switchAnimal(0); check(d.fullness==23,"original pet restored"); d.switchAnimal(1); check(d.fullness==66,"second pet restored")
d.fox.sleeping=true; d.manualSleep=false; d.toggleSleep(); check(!d.fox.sleeping,"wake automatic sleep")
d.mediaCheck=Double.greatestFiniteMagnitude; d.nextAction=Double.greatestFiniteMagnitude
let now=ProcessInfo.processInfo.systemUptime; d.last=now; d.lastMouseTime=now-100
let mouse=d.lastMouse
d.tick(now:now+0.1,mouse:mouse,keyboardIdleOverride:0); check(!d.fox.sleeping && d.fox.typing,"typing wakes")
d.tick(now:now+1,mouse:mouse,keyboardIdleOverride:1); check(!d.fox.sleeping,"typing resets idle deadline")
d.tick(now:now+40,mouse:mouse,keyboardIdleOverride:40); check(d.fox.sleeping,"idle sleeps")
prefs.removePersistentDomain(forName:"LittlePals.AuditTests")
d.careEnabled=false; d.manualSleep=true; d.fox.sleeping=true; d.greet(); check(!d.fox.sleeping && !d.manualSleep && d.fox.affection>0,"click wakes and greets")
d.fox.hovered=true; d.fox.walking=true; d.tick(now:now+41,mouse:mouse,keyboardIdleOverride:0); check(!d.fox.walking,"hover stops wandering")
d.applySize(0.75); check(d.window.frame.width==135 && d.fox.bounds.width==180,"small keeps logical canvas")
d.applySize(1.25); check(d.window.frame.width==225 && d.fox.bounds.width==180,"large keeps logical canvas")
for animal in 0..<3 {
 d.switchAnimal(animal); d.careEnabled=true; d.feed(); check(d.fox.activity=="food" && d.fox.affection==5,"visible eating")
 d.energy=50; d.play(); check(d.fox.activity=="play" && !d.fox.walking,"playing holds position")
}
for a in 0..<3 {
 let v=FoxView(frame:NSRect(x:0,y:0,width:180,height:185)); v.animal=a;v.sleeping=true
 check(v.opaque(at:NSPoint(x:90,y:30)),"sleep body catches mouse")
 check(!v.opaque(at:NSPoint(x:90,y:155)),"empty space passes through")
}
print("PASS: \(checks) checks")
