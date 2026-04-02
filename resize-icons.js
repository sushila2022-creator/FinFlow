const sharp = require('sharp');
const path = require('path');

const sourceIcon = 'assets/icon/icon.png';
const webIconsDir = 'web/icons';
const splashImgDir = 'web/splash/img';

async function resizeIcon(input, output, width, height) {
  await sharp(input)
    .resize(width, height, {
      fit: 'fill',
    })
    .toFile(output);
  console.log(`Created: ${output} (${width}x${height})`);
}

async function createSplashImage(input, output, backgroundColor) {
  // Get metadata to know the original dimensions
  const metadata = await sharp(input).metadata();
  const width = metadata.width;
  const height = metadata.height;
  
  // Calculate a reasonable size for the icon on the splash screen
  // The icon should be centered and not too large
  const iconSize = Math.min(width, height) * 0.4; // 40% of the smallest dimension
  
  // Create the background
  const background = sharp({
    create: {
      width: width,
      height: height,
      channels: 4,
      background: backgroundColor
    }
  });
  
  // Resize and composite the icon
  await background
    .composite([{
      input: await sharp(input).resize(iconSize, iconSize, { fit: 'fill' }).toBuffer(),
      gravity: 'center'
    }])
    .png()
    .toFile(output);
  
  console.log(`Created: ${output} (${width}x${height}) with ${backgroundColor} background`);
}

async function main() {
  try {
    console.log('Processing FinFlow icons...\n');
    
    // Resize web icons
    await resizeIcon(sourceIcon, path.join(webIconsDir, 'Icon-192.png'), 192, 192);
    await resizeIcon(sourceIcon, path.join(webIconsDir, 'Icon-512.png'), 512, 512);
    await resizeIcon(sourceIcon, path.join(webIconsDir, 'Icon-maskable-192.png'), 192, 192);
    await resizeIcon(sourceIcon, path.join(webIconsDir, 'Icon-maskable-512.png'), 512, 512);
    
    console.log('\nProcessing splash images...\n');
    
    // Create splash images with #0D2B45 background
    // Assuming standard splash screen sizes (similar to 1x, 2x, 3x, 4x multipliers)
    // Common splash screen sizes for different pixel ratios
    const splashSizes = [
      { file: 'dark-1x.png', width: 320, height: 640 },
      { file: 'dark-2x.png', width: 640, height: 1280 },
      { file: 'dark-3x.png', width: 960, height: 1920 },
      { file: 'dark-4x.png', width: 1280, height: 2560 },
      { file: 'light-1x.png', width: 320, height: 640 },
      { file: 'light-2x.png', width: 640, height: 1280 },
      { file: 'light-3x.png', width: 960, height: 1920 },
      { file: 'light-4x.png', width: 1280, height: 2560 }
    ];
    
    for (const size of splashSizes) {
      const output = path.join(splashImgDir, size.file);
      
      // Create background with #0D2B45 color
      const background = sharp({
        create: {
          width: size.width,
          height: size.height,
          channels: 4,
          background: { r: 13, g: 43, b: 69, alpha: 1 } // #0D2B45
        }
      });
      
      // Calculate icon size (proportional to screen size)
      const iconSize = Math.min(size.width, size.height) * 0.3;
      
      // Resize the source icon
      const resizedIcon = await sharp(sourceIcon)
        .resize(iconSize, iconSize, { fit: 'fill' })
        .toBuffer();
      
      // Composite icon onto background
      await background
        .composite([{
          input: resizedIcon,
          gravity: 'center'
        }])
        .png()
        .toFile(output);
      
      console.log(`Created: ${output} (${size.width}x${size.height})`);
    }
    
    console.log('\n✅ All icons and splash images have been updated successfully!');
    
  } catch (error) {
    console.error('Error processing images:', error);
    process.exit(1);
  }
}

main();