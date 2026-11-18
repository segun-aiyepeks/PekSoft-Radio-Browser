'use client';

import { useEffect, useState } from 'react';
import {
  Bell,
  ChevronDown,
  Moon,
  Play,
  Radio,
  Sparkles,
  Sun,
  Volume2,
} from 'lucide-react';
import { toast } from 'sonner';
import { AnimatedBackground } from '@/components/motion-primitives/animated-background';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { BorderTrail } from '@/components/motion-primitives/border-trail';
import { InView } from '@/components/motion-primitives/in-view';
import { InfiniteSlider } from '@/components/motion-primitives/infinite-slider';
import { Magnetic } from '@/components/motion-primitives/magnetic';
import {
  MorphingDialog,
  MorphingDialogClose,
  MorphingDialogContainer,
  MorphingDialogContent,
  MorphingDialogDescription,
  MorphingDialogTitle,
  MorphingDialogTrigger,
} from '@/components/motion-primitives/morphing-dialog';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { SlidingNumber } from '@/components/motion-primitives/sliding-number';
import { Spotlight } from '@/components/motion-primitives/spotlight';
import { TextEffect } from '@/components/motion-primitives/text-effect';
import { TextShimmer } from '@/components/motion-primitives/text-shimmer';
import { Tilt } from '@/components/motion-primitives/tilt';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Drawer,
  DrawerContent,
  DrawerDescription,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
} from '@/components/ui/drawer';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Input } from '@/components/ui/input';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet';
import { Skeleton } from '@/components/ui/skeleton';
import { Slider } from '@/components/ui/slider';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import { FADE_UP_VARIANTS, TRANSITION_NORMAL } from '@/lib/motion';

export function DevComponentsGallery() {
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const [listeners, setListeners] = useState(1248);
  const [volume, setVolume] = useState<number[]>([72]);
  const [dataSaver, setDataSaver] = useState(false);

  useEffect(() => {
    const root = document.documentElement;
    root.setAttribute('data-theme', theme);
    root.classList.remove('dark', 'light');
    root.classList.add(theme);
  }, [theme]);

  return (
    <div className="relative min-h-screen bg-background text-foreground">
      <ScrollProgress className="fixed top-0 z-50 h-1 bg-[var(--color-accent)]" />

      <div className="mx-auto max-w-6xl space-y-10 px-6 py-10">
        <header className="flex flex-wrap items-center justify-between gap-4 border-b border-border pb-6">
          <div>
            <Badge variant="quality" className="mb-2">
              DEV ONLY · MILESTONE 6.1
            </Badge>
            <h1 className="text-3xl font-bold tracking-tight">
              PekSoft Web Design System &amp; Motion Gallery
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Every restyled shadcn/ui primitive and Motion Primitive driven by{' '}
              <code>packages/design-tokens</code> and <code>src/lib/motion.ts</code>.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <Button
              variant="outline"
              onClick={() =>
                setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'))
              }
            >
              {theme === 'dark' ? (
                <>
                  <Sun className="size-4" /> Switch to Light
                </>
              ) : (
                <>
                  <Moon className="size-4" /> Switch to Dark
                </>
              )}
            </Button>
          </div>
        </header>

        {/* Buttons & Badges */}
        <section className="space-y-4">
          <h2 className="text-xl font-semibold">Buttons &amp; Badges</h2>
          <Card>
            <CardHeader>
              <CardTitle>Button Variants (including Signal CTA)</CardTitle>
              <CardDescription>
                Restyled via CSS variables with visible focus rings and 48px-friendly touch targets.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex flex-wrap items-center gap-3">
                <Button variant="signal" size="lg">
                  <Play className="size-4" /> Signal Play CTA
                </Button>
                <Button variant="default">Default</Button>
                <Button variant="secondary">Secondary</Button>
                <Button variant="outline">Outline</Button>
                <Button variant="ghost">Ghost</Button>
                <Button variant="destructive">Destructive</Button>
                <Button variant="link">Link</Button>
                <Button variant="signal" disabled>
                  Disabled
                </Button>
              </div>
              <Separator />
              <div className="flex flex-wrap items-center gap-3">
                <Badge variant="live">
                  <span className="size-1.5 rounded-full bg-[var(--color-success)]" />
                  LIVE
                </Badge>
                <Badge variant="quality">AAC · 128 kbps</Badge>
                <Badge variant="default">Plus</Badge>
                <Badge variant="secondary">Afrobeats</Badge>
                <Badge variant="outline">HTTPS</Badge>
                <Badge variant="destructive">Unavailable</Badge>
              </div>
            </CardContent>
          </Card>
        </section>

        {/* Form, Controls & Overlays */}
        <section className="space-y-4">
          <h2 className="text-xl font-semibold">
            Inputs, Controls, Tabs, Overlays &amp; Feedback
          </h2>
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Inputs, Slider, Switch &amp; ToggleGroup</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center gap-3">
                  <Avatar>
                    <AvatarFallback>PK</AvatarFallback>
                  </Avatar>
                  <Input placeholder="Search stations, countries, or genres..." />
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">Data Saver (prefer lower bitrate)</span>
                  <Switch
                    checked={dataSaver}
                    onCheckedChange={setDataSaver}
                    aria-label="Toggle data saver"
                  />
                </div>
                <div className="flex items-center gap-3">
                  <Volume2 className="size-4 text-muted-foreground" />
                  <Slider
                    value={volume}
                    onValueChange={(val) =>
                      setVolume(Array.isArray(val) ? [...val] : [val])
                    }
                    max={100}
                    step={1}
                    aria-label="Volume"
                  />
                  <span className="w-10 text-right font-mono text-xs text-muted-foreground">
                    {volume[0]}%
                  </span>
                </div>
                <ToggleGroup defaultValue={['working']}>
                  <ToggleGroupItem value="working">Working now</ToggleGroupItem>
                  <ToggleGroupItem value="https">HTTPS only</ToggleGroupItem>
                  <ToggleGroupItem value="hls">HLS</ToggleGroupItem>
                </ToggleGroup>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Tabs, ScrollArea &amp; Overlays</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Tabs defaultValue="stations">
                  <TabsList>
                    <TabsTrigger value="stations">Stations</TabsTrigger>
                    <TabsTrigger value="countries">Countries</TabsTrigger>
                    <TabsTrigger value="genres">Genres</TabsTrigger>
                  </TabsList>
                  <TabsContent value="stations" className="pt-2">
                    <ScrollArea className="h-24 rounded-lg border border-border p-3">
                      <div className="space-y-2 text-sm">
                        <p>1. Cool FM 96.9 Lagos (AAC 128k)</p>
                        <p>2. FIP Paris (MP3 192k)</p>
                        <p>3. BBC World Service (AAC 96k)</p>
                        <p>4. Joy FM Accra (MP3 128k)</p>
                      </div>
                    </ScrollArea>
                  </TabsContent>
                  <TabsContent value="countries" className="pt-2 text-sm text-muted-foreground">
                    Nigeria · Ghana · United Kingdom · France · Japan
                  </TabsContent>
                  <TabsContent value="genres" className="pt-2 text-sm text-muted-foreground">
                    Afrobeats · Jazz · News · Highlife · Electronic
                  </TabsContent>
                </Tabs>

                <div className="flex flex-wrap gap-2">
                  <Dialog>
                    <DialogTrigger render={<Button variant="outline" size="sm" />}>
                      Dialog
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Report Broken Stream</DialogTitle>
                        <DialogDescription>
                          Help keep the Radio Browser directory accurate.
                        </DialogDescription>
                      </DialogHeader>
                    </DialogContent>
                  </Dialog>

                  <Sheet>
                    <SheetTrigger render={<Button variant="outline" size="sm" />}>
                      Sheet
                    </SheetTrigger>
                    <SheetContent>
                      <SheetHeader>
                        <SheetTitle>Filters</SheetTitle>
                        <SheetDescription>
                          Country, language, genre, codec, and bitrate.
                        </SheetDescription>
                      </SheetHeader>
                    </SheetContent>
                  </Sheet>

                  <Drawer>
                    <DrawerTrigger render={<Button variant="outline" size="sm" />}>
                      Drawer
                    </DrawerTrigger>
                    <DrawerContent>
                      <DrawerHeader>
                        <DrawerTitle>Sleep Timer</DrawerTitle>
                        <DrawerDescription>
                          Fade out playback automatically.
                        </DrawerDescription>
                      </DrawerHeader>
                    </DrawerContent>
                  </Drawer>

                  <Popover>
                    <PopoverTrigger render={<Button variant="outline" size="sm" />}>
                      Popover
                    </PopoverTrigger>
                    <PopoverContent>Stream health checked 2m ago.</PopoverContent>
                  </Popover>

                  <DropdownMenu>
                    <DropdownMenuTrigger render={<Button variant="outline" size="sm" />}>
                      Menu <ChevronDown className="size-3.5" />
                    </DropdownMenuTrigger>
                    <DropdownMenuContent>
                      <DropdownMenuItem>Add to collection</DropdownMenuItem>
                      <DropdownMenuItem>Share station</DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>

                  <Tooltip>
                    <TooltipTrigger render={<Button variant="outline" size="sm" />}>
                      Tooltip
                    </TooltipTrigger>
                    <TooltipContent>Surprise me with a live station</TooltipContent>
                  </Tooltip>

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => toast.success('Saved to Favourites')}
                  >
                    <Bell className="size-3.5" /> Toast
                  </Button>
                </div>

                <div className="space-y-2 pt-2">
                  <Skeleton className="h-4 w-2/3" />
                  <Skeleton className="h-4 w-1/2" />
                </div>
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Motion Primitives */}
        <section className="space-y-4">
          <h2 className="text-xl font-semibold">
            Motion Primitives (Reduced-Motion Aware)
          </h2>

          <Card>
            <CardContent className="space-y-6 pt-6">
              <div className="space-y-2">
                <span className="text-xs uppercase tracking-wider text-muted-foreground">
                  TextEffect &amp; TextShimmer
                </span>
                <TextEffect
                  per="word"
                  preset="fade-in-blur"
                  className="text-2xl font-bold"
                >
                  Every radio station in the world, one tap away.
                </TextEffect>
                <div>
                  <TextShimmer className="text-sm font-medium">
                    Connecting to live broadcast stream...
                  </TextShimmer>
                </div>
              </div>

              <Separator />

              <div className="flex flex-wrap items-center gap-6">
                <Magnetic>
                  <Button variant="signal">
                    <Radio className="size-4" /> Magnetic CTA
                  </Button>
                </Magnetic>

                <div className="relative overflow-hidden rounded-xl border border-border bg-card px-5 py-3">
                  <BorderTrail className="bg-[var(--color-accent)]" size={48} />
                  <span className="relative z-10 text-sm font-medium">
                    BorderTrail Active Card
                  </span>
                </div>

                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-1 font-mono text-2xl font-bold">
                    <SlidingNumber value={listeners} />
                    <span className="text-xs font-normal text-muted-foreground">
                      listeners
                    </span>
                  </div>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => setListeners((n) => n + 27)}
                  >
                    +27
                  </Button>
                </div>
              </div>

              <Separator />

              <div className="grid gap-4 md:grid-cols-2">
                <Tilt rotationFactor={6}>
                  <div className="relative overflow-hidden rounded-xl border border-border bg-card p-6">
                    <Spotlight className="from-amber-400/20 via-amber-400/10 to-transparent" />
                    <Sparkles className="mb-2 size-5 text-[var(--color-accent)]" />
                    <h3 className="font-semibold">Tilt + Spotlight Card</h3>
                    <p className="text-sm text-muted-foreground">
                      Used on curated hero and collection cards.
                    </p>
                  </div>
                </Tilt>

                <MorphingDialog transition={TRANSITION_NORMAL}>
                  <MorphingDialogTrigger className="flex flex-col items-start justify-center rounded-xl border border-border bg-card p-6 text-left hover:border-[var(--color-accent)]/60">
                    <MorphingDialogTitle className="font-semibold">
                      MorphingDialog Player Preview
                    </MorphingDialogTitle>
                    <MorphingDialogDescription className="text-sm text-muted-foreground">
                      Click to expand from mini-bar into full player sheet.
                    </MorphingDialogDescription>
                  </MorphingDialogTrigger>
                  <MorphingDialogContainer>
                    <MorphingDialogContent className="w-full max-w-md rounded-2xl border border-border bg-card p-6">
                      <MorphingDialogTitle className="text-xl font-bold">
                        Cool FM 96.9 Lagos
                      </MorphingDialogTitle>
                      <MorphingDialogDescription className="mt-1 text-sm text-muted-foreground">
                        Live · AAC 128 kbps · Nigeria
                      </MorphingDialogDescription>
                      <div className="mt-6 flex justify-end">
                        <MorphingDialogClose className="rounded-lg border border-border px-4 py-2 text-sm">
                          Close
                        </MorphingDialogClose>
                      </div>
                    </MorphingDialogContent>
                  </MorphingDialogContainer>
                </MorphingDialog>
              </div>

              <Separator />

              <div className="space-y-2">
                <span className="text-xs uppercase tracking-wider text-muted-foreground">
                  AnimatedBackground Tabs
                </span>
                <div className="inline-flex rounded-lg border border-border bg-muted p-1">
                  <AnimatedBackground
                    defaultValue="monthly"
                    className="rounded-md bg-card shadow-sm"
                    transition={TRANSITION_NORMAL}
                  >
                    {['monthly', 'annual'].map((plan) => (
                      <button
                        key={plan}
                        data-id={plan}
                        type="button"
                        className="px-4 py-1.5 text-sm font-medium capitalize text-foreground"
                      >
                        {plan}
                      </button>
                    ))}
                  </AnimatedBackground>
                </div>
              </div>

              <Separator />

              <InView
                variants={{
                  hidden: { opacity: 0, y: 12 },
                  visible: { opacity: 1, y: 0 },
                }}
                transition={TRANSITION_NORMAL}
              >
                <AnimatedGroup
                  variants={FADE_UP_VARIANTS}
                  className="grid gap-3 sm:grid-cols-3"
                >
                  {['Nigeria 🇳🇬', 'United Kingdom 🇬🇧', 'Japan 🇯🇵'].map(
                    (country) => (
                      <div
                        key={country}
                        className="rounded-xl border border-border bg-card p-4 text-sm font-medium"
                      >
                        {country}
                      </div>
                    ),
                  )}
                </AnimatedGroup>
              </InView>

              <InfiniteSlider gap={16} speed={40} speedOnHover={15}>
                {[
                  'Cool FM 96.9',
                  'FIP Paris',
                  'BBC World Service',
                  'Joy FM Accra',
                  'J-Wave Tokyo',
                  'KEXP Seattle',
                ].map((station) => (
                  <div
                    key={station}
                    className="rounded-full border border-border bg-muted px-4 py-1.5 text-xs font-medium whitespace-nowrap"
                  >
                    {station}
                  </div>
                ))}
              </InfiniteSlider>
            </CardContent>
          </Card>
        </section>
      </div>
    </div>
  );
}
