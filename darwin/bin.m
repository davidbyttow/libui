// 28 april 2015
#import "uipriv_darwin.h"

struct bin {
	uiContainer c;
	void (*baseDestroy)(uiControl *);
	uiControl *mainControl;
	intmax_t marginLeft;
	intmax_t marginTop;
	intmax_t marginRight;
	intmax_t marginBottom;
};

void binDestroy(uiControl *c)
{
	struct bin *b = (struct bin *) c;

	// we can't check for an OS parent here because what we're working with with bin isn't subviews but rather content views (at least I think... TODO)
	// don't chain up to base here; we need to destroy children ourselves first
	if (b->mainControl != NULL) {
		uiControlSetParent(b->mainControl, NULL);
		uiControlDestroy(b->mainControl);
	}
	// NOW we can chain up to base
	(*(b->baseDestroy))(uiControl(b));
	uiFree(b);
}

void binPreferredSize(uiControl *c, uiSizing *d, intmax_t *width, intmax_t *height)
{
	struct bin *b = (struct bin *) c;
	intmax_t marginX, marginY;

	if (b->mainControl == NULL) {
		*width = 0;
		*height = 0;
		return;
	}
	uiControlPreferredSize(b->mainControl, d, width, height);
	marginX = b->marginLeft + b->marginRight;
	marginY = b->marginTop + b->marginBottom;
	*width += marginX;
	*height += marginY;
}

void binResizeChildren(uiContainer *c, intmax_t x, intmax_t y, intmax_t width, intmax_t height, uiSizing *d)
{
	struct bin *b = (struct bin *) c;

	if (b->mainControl == NULL)
		return;
	x += b->marginLeft;
	y += b->marginTop;
	width -= b->marginLeft + b->marginRight;
	height -= b->marginTop + b->marginBottom;
	uiControlResize(b->mainControl, x, y, width, height, d);
}

uiContainer *newBin(void)
{
	struct bin *b;

	b = uiNew(struct bin);

	uiMakeContainer(uiContainer(b));

	b->baseDestroy = uiControl(b)->Destroy;
	uiControl(b)->Destroy = binDestroy;
	uiControl(b)->PreferredSize = binPreferredSize;

	uiContainer(b)->ResizeChildren = binResizeChildren;

	return uiContainer(b);
}

void binSetMainControl(uiContainer *c, uiControl *mainControl)
{
	struct bin *b = (struct bin *) c;

	if (b->mainControl != NULL)
		uiControlSetParent(b->mainControl, NULL);
	b->mainControl = mainControl;
	if (b->mainControl != NULL)
		uiControlSetParent(b->mainControl, uiContainer(b));
	uiContainerUpdate(uiContainer(b));
}

void binSetMargins(uiContainer *c, intmax_t left, intmax_t top, intmax_t right, intmax_t bottom)
{
	struct bin *b = (struct bin *) c;

	b->marginLeft = left;
	b->marginRight = right;
	b->marginTop = top;
	b->marginBottom = bottom;
	uiContainerUpdate(uiContainer(b));
}

void binSetParent(uiContainer *c, uintptr_t osParent)
{
	complain("binSetParent() ineffective on OS X; specific selectors need to be called instead");
}
