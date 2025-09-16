import formidable from "formidable";
import fs from "fs";
import path from "path";
import ffmpeg from "fluent-ffmpeg";
import axios from "axios";

export const config = {
  api: {
    bodyParser: false, // needed for file uploads
  },
};

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const form = formidable({ 
    multiples: false,
    maxFileSize: 100 * 1024 * 1024, // 100MB limit
  });

  try {
    const [fields, files] = await new Promise((resolve, reject) => {
      form.parse(req, (err, fields, files) => {
        if (err) reject(err);
        else resolve([fields, files]);
      });
    });

    const topic = Array.isArray(fields.topic) ? fields.topic[0] : fields.topic || "Video Thumbnail";
    const description = Array.isArray(fields.description) ? fields.description[0] : fields.description || "";
    const videoFile = Array.isArray(files.video) ? files.video[0] : files.video;

    if (!videoFile) {
      return res.status(400).json({ error: "No video uploaded" });
    }

    console.log("Processing video:", videoFile.originalFilename);
    console.log("Topic:", topic);
    console.log("Description:", description);

    // Save video temporarily
    const tempVideoPath = videoFile.filepath;
    const thumbnailPath = path.join("/tmp", `thumbnail_${Date.now()}.jpg`);

    // Extract frame using FFmpeg at multiple timestamps to get the best frame
    const timestamps = ["1", "3", "5"]; // Try different timestamps
    let bestThumbnail = null;

    for (let i = 0; i < timestamps.length; i++) {
      const currentThumbnailPath = path.join("/tmp", `thumbnail_${Date.now()}_${i}.jpg`);
      
      try {
        await new Promise((resolve, reject) => {
          ffmpeg(tempVideoPath)
            .screenshots({
              timestamps: [timestamps[i]],
              filename: path.basename(currentThumbnailPath),
              folder: path.dirname(currentThumbnailPath),
              size: "640x480", // Higher resolution
            })
            .on("end", () => {
              console.log(`Thumbnail ${i + 1} generated successfully`);
              resolve();
            })
            .on("error", (err) => {
              console.error(`Error generating thumbnail ${i + 1}:`, err);
              reject(err);
            });
        });

        // Check if file exists and has content
        if (fs.existsSync(currentThumbnailPath) && fs.statSync(currentThumbnailPath).size > 0) {
          bestThumbnail = currentThumbnailPath;
          break; // Use the first successful thumbnail
        }
      } catch (error) {
        console.log(`Failed to generate thumbnail at ${timestamps[i]}s, trying next timestamp...`);
        continue;
      }
    }

    if (!bestThumbnail) {
      return res.status(500).json({ error: "Failed to extract video thumbnail" });
    }

    // Optional: Enhance thumbnail with AI (if you have OpenAI API key)
    let enhancedThumbnail = bestThumbnail;
    
    if (process.env.OPENAI_API_KEY && (topic !== "Video Thumbnail" || description)) {
      try {
        enhancedThumbnail = await enhanceThumbnailWithAI(bestThumbnail, topic, description);
      } catch (aiError) {
        console.log("AI enhancement failed, using original thumbnail:", aiError.message);
        // Continue with original thumbnail if AI fails
      }
    }

    // Read the final thumbnail
    const thumbnailData = fs.readFileSync(enhancedThumbnail, { encoding: "base64" });

    // Clean up temporary files
    try {
      fs.unlinkSync(bestThumbnail);
      if (enhancedThumbnail !== bestThumbnail) {
        fs.unlinkSync(enhancedThumbnail);
      }
      // Clean up any other temporary thumbnails
      timestamps.forEach((_, i) => {
        const tempPath = path.join("/tmp", `thumbnail_${Date.now()}_${i}.jpg`);
        if (fs.existsSync(tempPath)) {
          fs.unlinkSync(tempPath);
        }
      });
    } catch (cleanupError) {
      console.log("Cleanup error:", cleanupError.message);
    }

    // Get video metadata
    const videoInfo = await getVideoInfo(tempVideoPath);

    res.status(200).json({
      message: "Thumbnail generated successfully",
      thumbnailBase64: thumbnailData,
      metadata: {
        topic,
        description,
        videoInfo,
        enhanced: enhancedThumbnail !== bestThumbnail,
      },
    });

  } catch (error) {
    console.error("Error in thumbnail generation:", error);
    res.status(500).json({ 
      error: "Internal server error", 
      details: error.message 
    });
  }
}

// Function to get video metadata
async function getVideoInfo(videoPath) {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(videoPath, (err, metadata) => {
      if (err) {
        reject(err);
      } else {
        const videoStream = metadata.streams.find(stream => stream.codec_type === 'video');
        resolve({
          duration: metadata.format.duration,
          width: videoStream?.width,
          height: videoStream?.height,
          fps: videoStream?.r_frame_rate,
          codec: videoStream?.codec_name,
        });
      }
    });
  });
}

// Optional AI enhancement function (requires OpenAI API key)
async function enhanceThumbnailWithAI(thumbnailPath, topic, description) {
  try {
    // Read the original thumbnail
    const originalImage = fs.readFileSync(thumbnailPath, { encoding: "base64" });
    
    // Create a text overlay or enhancement prompt
    const enhancementPrompt = `Create an engaging thumbnail for a video about "${topic}". ${description ? `The video is about: ${description}` : ''}. Make it eye-catching and professional.`;
    
    // Note: This is a placeholder for AI enhancement
    // You would integrate with services like:
    // - OpenAI DALL-E for image generation
    // - Stability AI for image enhancement
    // - Custom ML models for thumbnail optimization
    
    console.log("AI Enhancement prompt:", enhancementPrompt);
    
    // For now, return the original thumbnail
    // In a real implementation, you would:
    // 1. Send the image and prompt to an AI service
    // 2. Get the enhanced image back
    // 3. Save it and return the path
    
    return thumbnailPath;
    
  } catch (error) {
    console.error("AI Enhancement error:", error);
    throw error;
  }
}

// Alternative: Simple text overlay enhancement
async function addTextOverlayToThumbnail(thumbnailPath, topic, description) {
  const outputPath = path.join("/tmp", `enhanced_thumbnail_${Date.now()}.jpg`);
  
  return new Promise((resolve, reject) => {
    // Create a simple text overlay using FFmpeg
    const overlayText = topic.length > 20 ? topic.substring(0, 20) + "..." : topic;
    
    ffmpeg(thumbnailPath)
      .videoFilters([
        {
          filter: 'drawtext',
          options: {
            text: overlayText,
            fontsize: 24,
            fontcolor: 'white',
            x: '10',
            y: '10',
            shadowcolor: 'black',
            shadowx: 2,
            shadowy: 2
          }
        }
      ])
      .output(outputPath)
      .on('end', () => {
        console.log('Text overlay added successfully');
        resolve(outputPath);
      })
      .on('error', (err) => {
        console.error('Error adding text overlay:', err);
        reject(err);
      })
      .run();
  });
}

// Enhanced version with better text styling
async function createStylizedThumbnail(thumbnailPath, topic, description) {
  const outputPath = path.join("/tmp", `stylized_thumbnail_${Date.now()}.jpg`);
  
  return new Promise((resolve, reject) => {
    const overlayText = topic.length > 25 ? topic.substring(0, 25) + "..." : topic;
    
    ffmpeg(thumbnailPath)
      .videoFilters([
        // Add a semi-transparent background for text
        {
          filter: 'drawbox',
          options: {
            x: 0,
            y: 'h-60',
            width: 'iw',
            height: 60,
            color: 'black@0.7',
            thickness: 'fill'
          }
        },
        // Add the main title text
        {
          filter: 'drawtext',
          options: {
            text: overlayText,
            fontsize: 20,
            fontcolor: 'white',
            x: '10',
            y: 'h-45',
            shadowcolor: 'black',
            shadowx: 1,
            shadowy: 1,
            fontfile: '/System/Library/Fonts/Helvetica.ttc' // Use system font if available
          }
        },
        // Add a play button overlay
        {
          filter: 'drawtext',
          options: {
            text: '▶',
            fontsize: 40,
            fontcolor: 'white@0.8',
            x: '(w-text_w)/2',
            y: '(h-text_h)/2',
            shadowcolor: 'black',
            shadowx: 2,
            shadowy: 2
          }
        }
      ])
      .outputOptions([
        '-q:v', '2', // High quality
        '-vf', 'scale=640:480' // Ensure consistent size
      ])
      .output(outputPath)
      .on('end', () => {
        console.log('Stylized thumbnail created successfully');
        resolve(outputPath);
      })
      .on('error', (err) => {
        console.error('Error creating stylized thumbnail:', err);
        // Fallback to original if styling fails
        resolve(thumbnailPath);
      })
      .run();
  });
}