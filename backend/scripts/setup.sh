#!/bin/bash

echo "🚀 Setting up Event Planning App Backend..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# Check if MongoDB is running
if ! pgrep -x "mongod" > /dev/null; then
    echo "⚠️  MongoDB is not running. Please start MongoDB first."
    echo "   You can start it with: brew services start mongodb/brew/mongodb-community"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Copy environment file
if [ ! -f .env ]; then
    echo "📝 Creating environment file..."
    cp .env.example .env
    echo "⚠️  Please update the .env file with your configuration before starting the server"
else
    echo "✅ Environment file already exists"
fi

echo "🌱 Seeding database with sample data..."
node src/utils/seedData.js

echo ""
echo "🎉 Backend setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Update the .env file if needed"
echo "   2. Run 'npm run dev' to start the development server"
echo "   3. Server will be available at http://localhost:5000"
echo ""
echo "🔐 Admin credentials:"
echo "   Owner Admin: admin / owner123"
echo "   User Admin: useradmin / admin123"
echo ""
echo "👤 Sample user credentials:"
echo "   demo@example.com / password123"
echo ""