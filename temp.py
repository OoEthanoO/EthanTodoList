from PIL import Image
import sys

def make_black_transparent(input_path, output_path):
    """
    Converts all black pixels in an image to transparent pixels.
    
    Args:
        input_path: Path to the input image file
        output_path: Path where the modified image will be saved
    """
    try:
        # Open the image
        img = Image.open(input_path)
        
        # Convert to RGBA if it isn't already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Get the pixel data
        datas = img.getdata()
        
        # Create a new data set with black pixels made transparent
        new_data = []
        for item in datas:
            # Check if the pixel is black (RGB values all 0)
            if not item[0] == 3 or not item[1] == 169 or not item[2] == 244:
                # Set the alpha value to 0 (fully transparent)
                new_data.append((0, 0, 0, 0))
            else:
                # Keep the original pixel
                new_data.append(item)
        
        # Update the image with the new data
        img.putdata(new_data)
        
        # Save the modified image
        img.save(output_path)
        print(f"Image successfully processed and saved as {output_path}")
        
    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    if len(sys.argv) == 3:
        make_black_transparent(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python black_to_transparent.py input_image.png output_image.png")
        # Example for direct usage in code
        # make_black_transparent("input.png", "output.png")