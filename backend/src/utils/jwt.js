const jwt = require('jsonwebtoken');

const generateToken = (payload, expiresIn = process.env.JWT_EXPIRE || '30d') => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn,
  });
};

const verifyToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

const generateAdminToken = (admin) => {
  return generateToken({
    id: admin._id,
    username: admin.username,
    email: admin.email,
    role: admin.role,
    permissions: admin.permissions,
    type: 'admin',
  });
};

const generateUserToken = (user) => {
  return generateToken({
    id: user._id,
    email: user.email,
    name: user.name,
    type: 'user',
  });
};

module.exports = {
  generateToken,
  verifyToken,
  generateAdminToken,
  generateUserToken,
};