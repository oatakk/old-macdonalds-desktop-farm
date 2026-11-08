# Walking artwork

The 18 PNGs in Assets/Walk were produced with OpenAI’s built-in ImageGen tool, using a contact sheet of this app’s original native pixel characters as a style/identity reference.

Prompt specification: a transparent six-column, three-row pixel-art sprite sheet. Orange fox with cream cheeks/tail tip; lavender cat with cream muzzle and curled tail; ivory rabbit with pink ears. Six consecutive side-view walking frames facing right, alternating four-paw contact for fox/cat and crouch/push-off/flight/landing/gather for rabbit. Consistent large heads, compact bodies, dark plum outlines, fixed ground baseline and generous transparent padding. No labels, grid lines, human limbs, gradients or cast shadows.

Frames were extracted from equal cells, aligned using a shared ground per species, sampled to 60×62 pixels, alpha-thresholded and displayed at 3× scale with interpolation disabled. The runtime needs no image-generation service or API key.

## App identity (v0.4.1)

The charcoal and cream fox icon was supplied by the project owner. The menu-bar template is sampled from that artwork. `Assets/Farm.icns.base64` and `Assets/MenuBarIcon.png.base64` are the distributable icon sources, decoded into the app bundle by the build script.
