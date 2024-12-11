package main

import (
	"bytes"
	"fmt"
	"io"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/timeout"
)

func main() {
	app := fiber.New()

	app.Use(cors.New())

	app.Get("/api", getExample)
	app.Post("/api", postExample)
	app.Put("/api", putExample)
	app.Delete("/api", deleteExample)
	app.Patch("/api", patchExample)
	app.Get("/api/query", queryExample)
	app.Get("/api/params/:id", paramsExample)
	app.Get("/api/headers", headersExample)
	app.Get("/api/error", errorExample)
	app.Get("/api/timeout", timeout.NewWithContext(timeoutExample, 5*time.Second))
	app.Get("/api/redirect", redirectExample)
	app.Get("/api/large-response", largeResponseExample)
	app.Get("/api/binary", binaryExample)
	app.Get("/api/cookies", cookiesExample)
	app.Get("/api/auth", authExample)

	// Start the server
	fmt.Println("Server is running on port 8000")
	app.Listen(":8000")
}

// GET Example
func getExample(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "GET request successful",
	})
}

// POST Example
func postExample(c *fiber.Ctx) error {
	body := new(map[string]interface{})
	if err := c.BodyParser(body); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}
	return c.JSON(fiber.Map{
		"message": "POST request successful",
		"data":    body,
	})
}

// PUT Example
func putExample(c *fiber.Ctx) error {
	body := new(map[string]interface{})
	if err := c.BodyParser(body); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}
	return c.JSON(fiber.Map{
		"message": "PUT request successful",
		"data":    body,
	})
}

// DELETE Example
func deleteExample(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "DELETE request successful",
	})
}

// PATCH Example
func patchExample(c *fiber.Ctx) error {
	body := new(map[string]interface{})
	if err := c.BodyParser(body); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}
	return c.JSON(fiber.Map{
		"message": "PATCH request successful",
		"data":    body,
	})
}

// Query Parameters Example
func queryExample(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Query parameters received",
		"query":   c.Queries(),
	})
}

// Route Parameters Example
func paramsExample(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Route parameters received",
		"params":  c.Params("id"),
	})
}

// Headers Example
func headersExample(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Headers received",
		"headers": c.GetReqHeaders(),
	})
}

// Error Example
func errorExample(c *fiber.Ctx) error {
	return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
		"error": "This is a bad request error",
	})
}

// Timeout Example
func timeoutExample(c *fiber.Ctx) error {
	time.Sleep(6 * time.Second) // Simulate a slow response
	return c.JSON(fiber.Map{
		"message": "This response was delayed by 6 seconds",
	})
}

// Redirect Example
func redirectExample(c *fiber.Ctx) error {
	return c.Redirect("https://www.google.com")
}

// Large Response Example
func largeResponseExample(c *fiber.Ctx) error {
	data := bytes.Repeat([]byte("a"), 100000) // 100KB of data
	return c.Send(data)
}

// Binary Example
func binaryExample(c *fiber.Ctx) error {
	file := bytes.NewReader([]byte{0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46}) // Example binary data
	c.Set("Content-Type", "application/octet-stream")
	_, err := io.Copy(c, file)
	return err
}

// Cookies Example
func cookiesExample(c *fiber.Ctx) error {
	c.Cookie(&fiber.Cookie{
		Name:     "session_id",
		Value:    "12345",
		HTTPOnly: true,
		MaxAge:   900000,
	})
	return c.JSON(fiber.Map{
		"message": "Cookie set",
	})
}

// Auth Example
func authExample(c *fiber.Ctx) error {
	authHeader := c.Get("Authorization")
	if authHeader == "Bearer my-secret-token" {
		return c.JSON(fiber.Map{
			"message": "Authenticated",
		})
	}
	return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
		"error": "Unauthorized",
	})
}
