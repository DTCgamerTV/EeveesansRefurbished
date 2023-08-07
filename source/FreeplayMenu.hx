package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayMenu extends MusicBeatState
{
	private static var curWeek:Int = 0;
	private static var curSong:Int = 0;
	private static var curDiff:Int = 1;
	
	var weekName:FlxText;

	var selectionBox:FlxSprite;
	var selectionArrow:FlxSprite;
	var selectionLine:FlxSprite;

	var grpSongs:FlxTypedGroup<SongBtn>;

    private var font:String = 'svfont.ttf';

	private var slPos:Array<Float> = [45, 146, 249];

	override function create()
	{
		persistentUpdate = true;
		
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		
        PlayState.isStoryMode = false;

		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

        var bg = new FlxSprite().makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), 0xFFA297F4);
		add(bg);

		var details = new FlxSprite().loadGraphic(Paths.image('freeplaymenu/details'));
		details.antialiasing = ClientPrefs.globalAntialiasing;
		add(details);

		var diffText = new FlxSprite().loadGraphic(Paths.image('freeplaymenu/diffText'));
		diffText.antialiasing = ClientPrefs.globalAntialiasing;
		diffText.setGraphicSize(Std.int(diffText.width / 2));
		diffText.updateHitbox();
		add(diffText);

		selectionLine = new FlxSprite(0, 40).loadGraphic(Paths.image('freeplaymenu/selectionLine'));
		selectionLine.antialiasing = ClientPrefs.globalAntialiasing;
		add(selectionLine);

		weekName = new FlxText(501, 82, 0, '', 20);
		weekName.setFormat(Paths.font(font), 55, FlxColor.WHITE, CENTER);
		weekName.antialiasing = ClientPrefs.globalAntialiasing;
		weekName.setGraphicSize(Std.int(weekName.width / 2));
		weekName.updateHitbox();
		add(weekName);

		selectionBox = new FlxSprite(24).loadGraphic(Paths.image('freeplaymenu/selectionBox'));
		selectionBox.antialiasing = ClientPrefs.globalAntialiasing;
		add(selectionBox);

		grpSongs = new FlxTypedGroup<SongBtn>();
		add(grpSongs);

		selectionArrow = new FlxSprite(182).loadGraphic(Paths.image('freeplaymenu/selectionArrow'));
		selectionArrow.antialiasing = ClientPrefs.globalAntialiasing;
		add(selectionArrow);

		changeWeek();
		changeSong();
		changeDiff();
    }

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		var leftP = controls.UI_LEFT_P;
		var downP = controls.UI_DOWN_P;
		var upP = controls.UI_UP_P;
		var rightP = controls.UI_RIGHT_P;
		var accept = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		if (controls.BACK)
		{
			persistentUpdate = false;
			
			FlxG.sound.play(Paths.sound('cancelMenu'));

			MusicBeatState.switchState(new MainMenuState());
		}

		if (accept)
			chooseSong();

		if (leftP || rightP)
			changeWeek(leftP ? -1 : 1);

		if (upP || downP)
			changeSong(upP ? -1 : 1);

		if (FlxG.keys.justPressed.E)
			changeDiff(1);
	}

	function chooseSong():Void
	{
		var songs:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;

		var songLowercase:String = Paths.formatToSongPath(songs[curSong][0]);
		var songFormatted:String = Highscore.formatSong(songLowercase, curDiff);

		PlayState.SONG = Song.loadFromJson(songFormatted, songLowercase);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDiff;
		
		if (FlxG.keys.pressed.SHIFT)
			LoadingState.loadAndSwitchState(new ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());

		FlxG.sound.music.volume = 0;
		
		persistentUpdate = false;

		trace(songFormatted);
		trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek = (curWeek + change) % WeekData.weeksList.length;

		if (curWeek < 0)
			curWeek = WeekData.weeksList.length - 1;

		var week:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);

		weekName.text = week.weekName;
		weekName.updateHitbox();

		var songLength = grpSongs.members.length;

		for (i in 0...songLength)
		{
			var song = grpSongs.members[0];

			song.kill();
			grpSongs.remove(song, true);
			song.destroy();
		}

		for (i in 0...week.songs.length)
		{
			var songBtn = new SongBtn(24, 131 + 85 * i, week.songs[i]);
			grpSongs.add(songBtn);
		}

		if (curSong >= week.songs.length)
			changeSong(week.songs.length - (week.songs.length - 1));
		else
			changeSong();
	}

	function changeSong(change:Int = 0):Void
	{	
		var oldSong = curSong;

		var songs:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;

		curSong = (curSong + change) % songs.length;

		if (curSong < 0)
			curSong = songs.length - 1;
		
		selectionBox.y = 131 + 85 * curSong;
		selectionArrow.y = 120 + 85 * curSong;

		if (grpSongs.members[oldSong] != null)
			grpSongs.members[oldSong].changeSelection(false);

		grpSongs.members[curSong].changeSelection(true);
	}

	function changeDiff(change:Int = 0):Void
	{
		curDiff = (curDiff + change) % 3;

		if (curDiff < 0)
			curDiff = 2;
		
		selectionLine.x = slPos[curDiff];
	}
}

class SongBtn extends FlxSpriteGroup
{
	public var song:Array<Dynamic> = [];

	public var name:FlxText;

	public function new(?x:Float, ?y:Float, song:Array<Dynamic>)
	{
		super(x, y);

		this.song = song;

		var icon = new HealthIcon(150, 0, song[1]);
		icon.setGraphicSize(80);
		icon.updateHitbox();
		add(icon);

		name = new FlxText(13, 45, 0, song[0], 43);
		name.setFormat(Paths.font('svfont.ttf'), 43, FlxColor.WHITE);
		name.antialiasing = ClientPrefs.globalAntialiasing;
		name.setGraphicSize(Std.int(name.width / 2));
		name.updateHitbox();
		add(name);
	}

	public function changeSelection(selected:Bool):Void
	{
		if (selected)
			name.color = FlxColor.BLACK;
		else
			name.color = FlxColor.WHITE;
	}
}