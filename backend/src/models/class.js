const mongoose = require('mongoose');
const { Schema } = mongoose;

const classSchema = new Schema({
  name: { type: String, required: true },
  code: { type: String, required: true, unique: true },
  teacher: { type: Schema.Types.ObjectId, ref: 'Teacher' },
  description: String
}, { timestamps: true });

module.exports = mongoose.model('Class', classSchema);
